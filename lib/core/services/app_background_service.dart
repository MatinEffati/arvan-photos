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
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_manager/photo_manager.dart';
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
        isForegroundMode: true,
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
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  await NotificationService.initialize(service);
  try {
    await dotenv.load(fileName: 'assets/env');
  } catch (_) {}

  final db = await AppDatabase.open();
  final dio = Dio();
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

  bool isRunning = true;
  bool isPaused = false;
  final activeUploads = <String, CancelToken>{};
  
  service.on('stopService').listen((event) {
    isRunning = false;
    for (var token in activeUploads.values) {
      token.cancel('Service stopped');
    }
    service.stopSelf();
  });

  service.on('pause').listen((event) {
    isPaused = true;
    // For manual tasks, we might want to cancel current? 
    // But for simplicity let's just flag it.
    service.invoke('update', {'status': 'paused'});
  });

  service.on('resume').listen((event) {
    isPaused = false;
    service.invoke('update', {'status': 'resumed'});
  });

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (!isRunning) return;

    // 1. Handle Auto-Backup scanning
    final isAutoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? false;
    if (isAutoBackupEnabled) {
      await _scanAndEnqueueBackup(localDataSource: backupLocalDataSource, repository: repository);
    }

    if (isPaused) return;

    if (activeUploads.length >= AppBackgroundService.maxConcurrentUploads) {
      return;
    }

    // 2. Fetch Pending Tasks (Prioritize manual upload_tasks, then backup_queue)
    // For simplicity, we just process backup_queue for now as it's the new feature.
    // Or we could fetch from both.
    
    final pendingBackup = await backupLocalDataSource.getPending(
      AppBackgroundService.maxConcurrentUploads - activeUploads.length,
    );

    // If we have manual tasks in 'upload_tasks' table from the old system, we should also handle them.
    final manualTasks = await db.query(
      'upload_tasks',
      where: 'status = ?',
      whereArgs: [UploadStatus.pending.name],
      limit: AppBackgroundService.maxConcurrentUploads - activeUploads.length,
    );

    if (pendingBackup.isEmpty && manualTasks.isEmpty && activeUploads.isEmpty) {
      // Check if we should stop
      return;
    }

    // Process Manual Tasks
    for (var taskMap in manualTasks) {
      final taskId = taskMap['id'] as String;
      if (activeUploads.containsKey(taskId)) continue;
      _startManualUpload(
        taskMap: taskMap,
        service: service,
        db: db,
        repository: repository,
        activeUploads: activeUploads,
        backupLocalDataSource: backupLocalDataSource,
      );
    }

    // Process Backup Tasks
    for (final task in pendingBackup) {
      final assetId = task['local_asset_id'] as String;
      if (activeUploads.containsKey(assetId)) continue;

      _startBackupUpload(
        assetId: assetId,
        service: service,
        localDataSource: backupLocalDataSource,
        repository: repository,
        activeUploads: activeUploads,
        db: db,
      );
    }
  });
}

Future<void> _scanAndEnqueueBackup({
  required BackupLocalDataSource localDataSource,
  required PhotoRepositoryImpl repository,
}) async {
  final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
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
    final allInQueueIds = allInQueue.map((e) => e['local_asset_id'] as String).toSet();

    final toEnqueue = assets
        .where((a) => !syncedIdsSet.contains(a.id) && !allInQueueIds.contains(a.id))
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
  required Database db,
}) async {
  final cancelToken = CancelToken();
  activeUploads[assetId] = cancelToken;

  await localDataSource.updateStatus(assetId, 'uploading', progress: 0.0);
  service.invoke('status_update', {'assetId': assetId, 'status': 'uploading', 'progress': 0.0});

  try {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) throw Exception('Asset not found');
    
    final file = await asset.file;
    if (file == null) throw Exception('File not found');

    final result = await repository.uploadPhoto(
      file,
      cancelToken: cancelToken,
      onProgress: (progress) async {
        await localDataSource.updateStatus(assetId, 'uploading', progress: progress);
        service.invoke('status_update', {'assetId': assetId, 'status': 'uploading', 'progress': progress});
        await _updateOverallNotification(service, localDataSource);
      },
    );

    result.fold(
      (failure) async {
        await localDataSource.updateStatus(assetId, 'failed');
        service.invoke('status_update', {'assetId': assetId, 'status': 'failed'});
      },
      (success) async {
        final remoteKey = S3PhotoKeyGenerator().generateKey(file.path);
        await localDataSource.updateStatus(assetId, 'synced', remoteKey: remoteKey);
        service.invoke('status_update', {'assetId': assetId, 'status': 'synced'});
      },
    );
  } catch (e) {
    await localDataSource.updateStatus(assetId, 'failed');
    service.invoke('status_update', {'assetId': assetId, 'status': 'failed'});
  } finally {
    activeUploads.remove(assetId);
    await _updateOverallNotification(service, localDataSource);
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
  final taskId = taskMap['id'] as String;
  final filePath = taskMap['file_path'] as String;
  final localAssetId = taskMap['local_asset_id'] as String?;
  final file = File(filePath);

  final cancelToken = CancelToken();
  activeUploads[taskId] = cancelToken;

  await db.update('upload_tasks', {'status': UploadStatus.uploading.name}, where: 'id = ?', whereArgs: [taskId]);
  service.invoke('update', {'id': taskId, 'status': 'uploading'});

  final result = await repository.uploadPhoto(
    file,
    cancelToken: cancelToken,
    onProgress: (progress) async {
      await db.update('upload_tasks', {'progress': progress}, where: 'id = ?', whereArgs: [taskId]);
      service.invoke('update', {'id': taskId, 'progress': progress, 'status': 'uploading'});
    },
  );

  result.fold(
    (failure) async {
      await db.update('upload_tasks', {'status': UploadStatus.failure.name, 'error_message': failure.message}, where: 'id = ?', whereArgs: [taskId]);
      service.invoke('update', {'id': taskId, 'status': 'failure'});
    },
    (_) async {
      await db.update('upload_tasks', {'status': UploadStatus.success.name, 'progress': 1.0}, where: 'id = ?', whereArgs: [taskId]);
      if (localAssetId != null) {
        final key = S3PhotoKeyGenerator().generateKey(filePath);
        await backupLocalDataSource.updateStatus(localAssetId, 'synced', remoteKey: key);
      }
      service.invoke('update', {'id': taskId, 'status': 'success'});
    },
  );
  activeUploads.remove(taskId);
}

Future<void> _updateOverallNotification(ServiceInstance service, BackupLocalDataSource localDataSource) async {
  final all = await localDataSource.getAll();
  final total = all.length;
  if (total == 0) return;

  final synced = all.where((e) => e['status'] == 'synced').length;
  final uploading = all.where((e) => e['status'] == 'uploading');
  
  double currentProgress = 0.0;
  for (var task in uploading) {
    currentProgress += (task['progress'] as num? ?? 0.0).toDouble();
  }

  final overallProgress = (synced + currentProgress) / total;

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Backing up... ($synced/$total)',
      content: 'Overall Progress: ${(overallProgress * 100).toInt()}%',
    );
  }

  await NotificationService.showUploadProgress(
    id: AppBackgroundService.notificationId,
    title: 'Backing up... ($synced/$total)',
    progress: (overallProgress * 100).toInt(),
    total: 100,
  );
}
