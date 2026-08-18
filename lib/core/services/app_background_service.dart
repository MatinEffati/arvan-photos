import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:arvan_photos/core/config/app_config.dart';
import 'package:arvan_photos/core/database/app_database.dart';
import 'package:arvan_photos/core/network/arvan_s3_client.dart';
import 'package:arvan_photos/core/services/notification_service.dart';
import 'package:arvan_photos/features/photos/data/datasources/backup_local_datasource.dart';
import 'package:arvan_photos/features/photos/data/datasources/photo_key_generator.dart';
import 'package:arvan_photos/features/photos/data/datasources/photos_remote_data_source_impl.dart';
import 'package:arvan_photos/features/photos/data/repositories/photo_repository_impl.dart';
import 'package:arvan_photos/features/photos/domain/entities/upload_task.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class AppBackgroundService {
  static const int notificationId = 888;
  static const int maxConcurrentUploads = 5;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: false,
        notificationChannelId: 'upload_channel',
        initialNotificationTitle: 'Photo Service',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: notificationId,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: (service) async => true,
      ),
    );
  }

  static Future<void> start() async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }
  }
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  try {
    DartPluginRegistrant.ensureInitialized();

    await NotificationService.initialize(service);
    try {
      await dotenv.load(fileName: 'assets/env');
    } catch (_) {}

    final db = await AppDatabase.open();
    final dio = Dio();
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(requestHeader: true, requestBody: true),
      );
    }
    final config = AppConfig();
    final s3Client = ArvanS3Client(dio, config);
    final remoteDataSource = PhotosRemoteDataSourceImpl(s3Client);
    final keyGenerator = S3PhotoKeyGenerator();
    final backupLocalDataSource = BackupLocalDataSourceImpl(db);
    final prefs = await SharedPreferences.getInstance();

    final repository = PhotoRepositoryImpl(
      remoteDataSource,
      keyGenerator,
      backupLocalDataSource,
    );

    var isRunning = true;
    var isPaused = false;
    final activeUploads = <String, CancelToken>{};
    var lastQueueTotal = 0;

    service.on('stopService').listen((event) async {
      isRunning = false;
      for (final token in activeUploads.values) {
        token.cancel('Service stopped');
      }
      if (service is AndroidServiceInstance) {
        await service.stopSelf();
      }
    });

    service.on('pause').listen((event) {
      isPaused = true;
      service.invoke('update', {'status': 'paused'});
    });

    service.on('resume').listen((event) {
      isPaused = false;
      service.invoke('update', {'status': 'resumed'});
    });

    Future<void> runProcessingCycle() async {
      if (!isRunning || isPaused) return;

      try {
        final isAutoBackupEnabled =
            prefs.getBool('auto_backup_enabled') ?? false;
        if (isAutoBackupEnabled) {
          await _scanAndEnqueueBackup(
            localDataSource: backupLocalDataSource,
            repository: repository,
          );
        }
      } catch (e) {
        debugPrint('BACKUP_SERVICE_ERROR (Scan): $e');
      }

      if (activeUploads.length >= AppBackgroundService.maxConcurrentUploads) {
        return;
      }

      final allPending = await backupLocalDataSource.getPending(500);
      if (allPending.isNotEmpty && activeUploads.isEmpty) {
        lastQueueTotal = allPending.length;
      }

      final pendingBackup = await backupLocalDataSource.getPending(
        AppBackgroundService.maxConcurrentUploads - activeUploads.length,
      );

      final manualTasks = await db.query(
        'upload_tasks',
        where: 'status = ?',
        whereArgs: [UploadStatus.pending.name],
        limit: AppBackgroundService.maxConcurrentUploads - activeUploads.length,
      );

      if (pendingBackup.isEmpty &&
          manualTasks.isEmpty &&
          activeUploads.isEmpty) {
        await _updateOverallNotification(
          service,
          backupLocalDataSource,
          lastQueueTotal,
          isPaused: isPaused,
        );
        return;
      }

      for (final taskMap in manualTasks) {
        final taskId = taskMap['id']! as String;
        if (activeUploads.containsKey(taskId)) continue;
        unawaited(
          _startManualUpload(
            taskMap: taskMap,
            service: service,
            db: db,
            repository: repository,
            activeUploads: activeUploads,
            backupLocalDataSource: backupLocalDataSource,
          ),
        );
      }

      for (final task in pendingBackup) {
        final assetId = task['local_asset_id']! as String;
        if (activeUploads.containsKey(assetId)) continue;

        unawaited(
          _startBackupUpload(
            assetId: assetId,
            service: service,
            localDataSource: backupLocalDataSource,
            repository: repository,
            activeUploads: activeUploads,
          ),
        );
      }

      await _updateOverallNotification(
        service,
        backupLocalDataSource,
        lastQueueTotal,
        isPaused: isPaused,
      );
    }

    // Listen for immediate backup requests
    service.on('enqueue').listen((event) {
      unawaited(runProcessingCycle());
    });

    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!isRunning) {
        timer.cancel();
        return;
      }
      await runProcessingCycle();
    });
  } catch (e) {
    debugPrint('BACKUP_SERVICE_FATAL_ERROR: $e');
  }
}

Future<void> _scanAndEnqueueBackup({
  required BackupLocalDataSource localDataSource,
  required PhotoRepositoryImpl repository,
}) async {
  final paths = await PhotoManager.getAssetPathList(
    type: RequestType.image,
    onlyAll: true,
  );
  if (paths.isNotEmpty) {
    final allAlbum = paths.first;
    final count = await allAlbum.assetCountAsync;
    final assets = await allAlbum.getAssetListRange(start: 0, end: count);

    final syncedIds = await localDataSource.getSyncedIds();
    final syncedIdsSet = syncedIds.toSet();

    final allInQueue = await localDataSource.getAll();
    final allInQueueIds = allInQueue
        .map((e) => e['local_asset_id']! as String)
        .toSet();
    final manuallyRemovedIds = allInQueue
        .where((e) => e['status'] == 'manually_removed')
        .map((e) => e['local_asset_id']! as String)
        .toSet();

    final toEnqueue = assets
        .where(
          (a) =>
              !syncedIdsSet.contains(a.id) &&
              !allInQueueIds.contains(a.id) &&
              !manuallyRemovedIds.contains(a.id),
        )
        .map((a) => a.id)
        .toList();

    if (toEnqueue.isNotEmpty) {
      await repository.enqueueBackup(toEnqueue);
    }
  }
}

Future<void> _startBackupUpload({
  required String assetId,
  required ServiceInstance service,
  required BackupLocalDataSource localDataSource,
  required PhotoRepositoryImpl repository,
  required Map<String, CancelToken> activeUploads,
}) async {
  final cancelToken = CancelToken();
  activeUploads[assetId] = cancelToken;

  await localDataSource.updateStatus(assetId, 'uploading', progress: 0);
  service.invoke('status_update', {
    'assetId': assetId,
    'status': 'uploading',
    'progress': 0,
  });

  try {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) throw Exception('Asset not found');

    final file = await asset.file;
    if (file == null) throw Exception('File not found');

    final result = await repository.uploadPhoto(
      file,
      cancelToken: cancelToken,
      onProgress: (progress) async {
        await localDataSource.updateStatus(
          assetId,
          'uploading',
          progress: progress,
        );
        service.invoke('status_update', {
          'assetId': assetId,
          'status': 'uploading',
          'progress': progress,
        });
      },
    );

    await result.fold(
      (failure) async {
        await localDataSource.updateStatus(assetId, 'failed');
        service.invoke('status_update', {
          'assetId': assetId,
          'status': 'failed',
        });
      },
      (remoteKey) async {
        await localDataSource.updateStatus(
          assetId,
          'synced',
          remoteKey: remoteKey,
        );
        service.invoke('status_update', {
          'assetId': assetId,
          'status': 'synced',
        });
      },
    );
  } catch (e) {
    await localDataSource.updateStatus(assetId, 'failed');
    service.invoke('status_update', {'assetId': assetId, 'status': 'failed'});
  } finally {
    activeUploads.remove(assetId);
  }
}

Future<void> _startManualUpload({
  required Map<String, dynamic> taskMap,
  required ServiceInstance service,
  required Database db,
  required PhotoRepositoryImpl repository,
  required Map<String, CancelToken> activeUploads,
  required BackupLocalDataSource backupLocalDataSource,
}) async {
  final taskId = taskMap['id']! as String;
  final filePath = taskMap['file_path']! as String;
  final localAssetId = taskMap['local_asset_id'] as String?;
  final file = File(filePath);

  final cancelToken = CancelToken();
  activeUploads[taskId] = cancelToken;

  await db.update(
    'upload_tasks',
    {'status': UploadStatus.uploading.name},
    where: 'id = ?',
    whereArgs: [taskId],
  );
  service.invoke('update', {'id': taskId, 'status': 'uploading'});

  final result = await repository.uploadPhoto(
    file,
    cancelToken: cancelToken,
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
    },
  );

  await result.fold(
    (failure) async {
      await db.update(
        'upload_tasks',
        {'status': UploadStatus.failure.name, 'error_message': failure.message},
        where: 'id = ?',
        whereArgs: [taskId],
      );
      service.invoke('update', {'id': taskId, 'status': 'failure'});
    },
    (remoteKey) async {
      await db.update(
        'upload_tasks',
        {'status': UploadStatus.success.name, 'progress': 1},
        where: 'id = ?',
        whereArgs: [taskId],
      );
      if (localAssetId != null) {
        await backupLocalDataSource.updateStatus(
          localAssetId,
          'synced',
          remoteKey: remoteKey,
        );
      }
      service.invoke('update', {'id': taskId, 'status': 'success'});
    },
  );
  activeUploads.remove(taskId);
}

Future<void> _updateOverallNotification(
  ServiceInstance service,
  BackupLocalDataSource localDataSource,
  int lastQueueTotal, {
  bool isPaused = false,
}) async {
  final all = await localDataSource.getAll();
  final uploading = all.where((e) => e['status'] == 'uploading').length;
  final queued = all.where((e) => e['status'] == 'queued').length;

  final itemsLeft = queued + uploading;

  if (itemsLeft == 0) {
    if (service is AndroidServiceInstance) {
      await service.setAsBackgroundService();
    }

    final synced = all.where((e) => e['status'] == 'synced').length;
    if (synced > 0) {
      await NotificationService.showUploadProgress(
        id: AppBackgroundService.notificationId,
        title: 'Backup Complete',
        progress: 100,
        total: 100,
        isComplete: true,
      );
    } else {
      await NotificationService.cancel(AppBackgroundService.notificationId);
    }
    return;
  }

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
  }

  final total = lastQueueTotal > 0 ? lastQueueTotal : itemsLeft;
  final currentNum = (total - itemsLeft + 1).clamp(1, total);
  final title = isPaused
      ? 'Backup Paused'
      : 'Backing up... ($currentNum/$total)';

  if (service is AndroidServiceInstance) {
    await service.setForegroundNotificationInfo(
      title: title,
      content: isPaused ? 'Upload is paused' : 'Upload in progress...',
    );
  }

  await NotificationService.showUploadProgress(
    id: AppBackgroundService.notificationId,
    title: title,
    progress: (currentNum / total * 100).toInt(),
    total: 100,
    isPaused: isPaused,
  );
}
