import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:arvan_photos/core/config/app_config.dart';
import 'package:arvan_photos/core/network/arvan_s3_client.dart';
import 'package:arvan_photos/features/photos/data/datasources/photo_key_generator.dart';
import 'package:arvan_photos/features/photos/data/datasources/photos_remote_data_source_impl.dart';
import 'package:arvan_photos/features/photos/data/datasources/sync_local_datasource.dart';
import 'package:arvan_photos/features/photos/data/repositories/photo_repository_impl.dart';
import 'package:arvan_photos/features/photos/domain/entities/upload_task.dart';
import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:arvan_photos/core/services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite/sqflite.dart';

class BackgroundUploadService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'upload_channel',
        initialNotificationTitle: 'Photo Uploads',
        initialNotificationContent: 'Preparing upload queue...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize notifications in the background isolate
  await NotificationService.initialize();

  // Load dotenv for the background isolate
  try {
    await dotenv.load(fileName: 'assets/env');
  } catch (e) {
    print('BACKUP_SERVICE: Failed to load .env: $e');
  }

  bool isPaused = false;
  bool isRunning = true;
  CancelToken? currentCancelToken;

  service.on('pause').listen((event) {
    isPaused = true;
    currentCancelToken?.cancel('User paused');
    currentCancelToken = null;
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Uploading Photos (Paused)',
        content: 'Upload is paused',
      );
    }
    service.invoke('update', {'status': 'paused'});
  });

  service.on('resume').listen((event) {
    isPaused = false;
    service.invoke('update', {'status': 'resumed'});
  });

  service.on('stop').listen((event) {
    isRunning = false;
    currentCancelToken?.cancel('User stopped');
    service.stopSelf();
  });

  service.on('stopService').listen((event) {
    isRunning = false;
    currentCancelToken?.cancel('User stopped');
    service.stopSelf();
  });

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Manual dependency injection for the background isolate
  final db = await DatabaseProvider.getDatabase();
  final dio = Dio();
  final config = AppConfig();
  final s3Client = ArvanS3Client(dio, config);
  final remoteDataSource = PhotosRemoteDataSourceImpl(s3Client);
  final keyGenerator = S3PhotoKeyGenerator();
  final syncLocalDataSource = SyncLocalDataSourceImpl(db);
  final repository = PhotoRepositoryImpl(
    remoteDataSource,
    keyGenerator,
    syncLocalDataSource,
  );

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (!isRunning) return;

    if (isPaused) {
      service.invoke('update', {'status': 'paused'});
      return;
    }

    // Get next pending task from DB
    final tasks = await db.query(
      'upload_tasks',
      where: 'status = ?',
      whereArgs: [UploadStatus.pending.name],
      limit: 1,
    );

    if (tasks.isEmpty) {
      final stillUploading = await db.query(
        'upload_tasks',
        where: 'status = ?',
        whereArgs: [UploadStatus.uploading.name],
      );
      if (stillUploading.isEmpty) {
        // Check if all are done
        final allTasks = await db.query('upload_tasks');
        final allFinished = allTasks.every(
          (t) =>
              t['status'] == UploadStatus.success.name ||
              t['status'] == UploadStatus.failure.name,
        );
        if (allFinished && allTasks.isNotEmpty) {
          service.invoke('completed');
          service.stopSelf();
          isRunning = false;
        }
      }
      return;
    }

    final taskMap = tasks.first;
    final taskId = taskMap['id'] as String;
    final filePath = taskMap['file_path'] as String;
    final file = File(filePath);

    // Mark as uploading
    await db.update(
      'upload_tasks',
      {'status': UploadStatus.uploading.name},
      where: 'id = ?',
      whereArgs: [taskId],
    );

    service.invoke('update', {'id': taskId, 'status': 'uploading'});

    currentCancelToken = CancelToken();

    final result = await repository.uploadPhoto(
      file,
      cancelToken: currentCancelToken,
      onProgress: (progress) async {
        await db.update(
          'upload_tasks',
          {'progress': progress},
          where: 'id = ?',
          whereArgs: [taskId],
        );

        service.invoke('update', {
          'id': taskId,
          'progress': progress,
          'status': 'uploading',
        });

        // Update notification
        final allTasks = await db.query('upload_tasks');
        final totalCount = allTasks.length;
        final completedCount = allTasks
            .where((t) => t['status'] == UploadStatus.success.name)
            .length;
        final overallProgress = (completedCount + progress) / totalCount;

        await NotificationService.showUploadProgress(
          id: 888,
          title: 'Uploading Photos ($completedCount/$totalCount)',
          progress: (overallProgress * 100).toInt(),
          total: 100,
        );
      },
    );

    currentCancelToken = null;

    result.fold(
      (failure) async {
        // If it was cancelled by user, don't mark as failure, mark as pending again to resume later
        if (failure.message.contains('User paused')) {
          await db.update(
            'upload_tasks',
            {'status': UploadStatus.pending.name},
            where: 'id = ?',
            whereArgs: [taskId],
          );
          return;
        }

        await db.update(
          'upload_tasks',
          {
            'status': UploadStatus.failure.name,
            'error_message': failure.message,
          },
          where: 'id = ?',
          whereArgs: [taskId],
        );
        service.invoke('update', {'id': taskId, 'status': 'failure'});

        // Update notification on failure
        NotificationService.showUploadProgress(
          id: 888,
          title: 'Upload Failed',
          progress: 0,
          total: 1,
        );
      },
      (_) async {
        await db.update(
          'upload_tasks',
          {'status': UploadStatus.success.name, 'progress': 1.0},
          where: 'id = ?',
          whereArgs: [taskId],
        );
        service.invoke('update', {'id': taskId, 'status': 'success'});

        // Update notification on success of one file
        final allTasks = await db.query('upload_tasks');
        final totalCount = allTasks.length;
        final completedCount = allTasks
            .where((t) => t['status'] == UploadStatus.success.name)
            .length;

        NotificationService.showUploadProgress(
          id: 888,
          title: 'Uploading Photos ($completedCount/$totalCount)',
          progress: (completedCount / totalCount * 100).toInt(),
          total: 100,
        );
      },
    );
  });
}

// Helper to avoid re-writing logic in DatabaseModule for background use
class DatabaseProvider {
  static Future<Database> getDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/arvan_photos.db';
    return openDatabase(path);
  }
}
