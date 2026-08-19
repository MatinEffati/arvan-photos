import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:arvan_photos/core/di/injection.dart';
import 'package:arvan_photos/core/network/dio_upload_cancel_token.dart';
import 'package:arvan_photos/core/services/notification_service.dart';
import 'package:arvan_photos/features/photos/data/datasources/backup_local_datasource.dart';
import 'package:arvan_photos/features/photos/data/repositories/photo_repository_impl.dart';
import 'package:arvan_photos/features/photos/domain/entities/upload_task.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
        isForegroundMode: true, // Crucial for reliability on modern Android
        notificationChannelId: 'upload_channel',
        initialNotificationTitle: 'Photo Backup Service',
        initialNotificationContent: 'Preparing to sync...',
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
    
    // On Android, we must show a foreground notification immediately if isForegroundMode is true
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      service.setForegroundNotificationInfo(
        title: 'Arvan Photos',
        content: 'Service is starting...',
      );
    }

    debugPrint('BACKUP_SERVICE: Background isolate active');

    await NotificationService.initialize(service);
    try {
      await dotenv.load(fileName: 'assets/env');
    } catch (_) {}

    await configureDependencies();
    
    final db = getIt<Database>();
    final backupLocalDataSource = getIt<BackupLocalDataSource>();
    final repository = getIt<PhotoRepositoryImpl>();

    var isRunning = true;
    var isPaused = false;
    final activeUploads = <String, DioUploadCancelToken>{};
    var lastQueueTotal = 0;

    service.on('stopService').listen((event) async {
      debugPrint('BACKUP_SERVICE: Stopping service command received');
      isRunning = false;
      for (final token in activeUploads.values) {
        token.cancel('Service stopped');
      }
      if (service is AndroidServiceInstance) {
        await service.stopSelf();
      }
    });

    service.on('pause').listen((event) {
      debugPrint('BACKUP_SERVICE: Paused');
      isPaused = true;
      service.invoke('update', {'status': 'paused'});
    });

    service.on('resume').listen((event) {
      debugPrint('BACKUP_SERVICE: Resumed');
      isPaused = false;
      service.invoke('update', {'status': 'resumed'});
    });

    Future<void> runProcessingCycle() async {
      if (!isRunning) {
        debugPrint('BACKUP_SERVICE: Cycle skipped - service not running');
        return;
      }
      if (isPaused) {
        debugPrint('BACKUP_SERVICE: Cycle skipped - service paused');
        return;
      }

      debugPrint('BACKUP_SERVICE: Starting processing cycle. Active: ${activeUploads.length}');

      if (activeUploads.length >= AppBackgroundService.maxConcurrentUploads) {
        debugPrint('BACKUP_SERVICE: Max concurrent uploads reached');
        return;
      }

      final allPending = await backupLocalDataSource.getPending(500);
      debugPrint('BACKUP_SERVICE: Found ${allPending.length} pending backup tasks');
      
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
      
      debugPrint('BACKUP_SERVICE: Picking ${pendingBackup.length} backup and ${manualTasks.length} manual tasks');

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
        debugPrint('BACKUP_SERVICE: Starting manual upload for task $taskId');
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
        final assetId = task.localAssetId;
        if (activeUploads.containsKey(assetId)) continue;

        debugPrint('BACKUP_SERVICE: Starting backup upload for asset $assetId');
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
      debugPrint('BACKUP_SERVICE: Enqueue signal received');
      unawaited(runProcessingCycle());
    });

    // Start the first cycle immediately
    unawaited(runProcessingCycle());

    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!isRunning) {
        timer.cancel();
        return;
      }
      await runProcessingCycle();
    });
  } catch (e, stack) {
    debugPrint('BACKUP_SERVICE_FATAL_ERROR: $e');
    debugPrint(stack.toString());
  }
}

// Removed _scanAndEnqueueBackup because PhotoManager is not isolate-safe.

Future<void> _startBackupUpload({
  required String assetId,
  required ServiceInstance service,
  required BackupLocalDataSource localDataSource,
  required PhotoRepositoryImpl repository,
  required Map<String, DioUploadCancelToken> activeUploads,
}) async {
  final cancelToken = DioUploadCancelToken();
  activeUploads[assetId] = cancelToken;

  await localDataSource.updateStatus(assetId, 'uploading', progress: 0);
  service.invoke('status_update', {
    'assetId': assetId,
    'status': 'uploading',
    'progress': 0,
  });

  try {
    final task = await localDataSource.getById(assetId);
    final filePath = task?.filePath;

    if (filePath == null) {
      throw Exception('File path not found in database for asset $assetId');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('BACKUP_SERVICE: File MISSING at path: $filePath');
      throw Exception('File does not exist at path: $filePath');
    }

    debugPrint('BACKUP_SERVICE: Starting Arvan S3 upload for $filePath');
    final result = await repository.uploadPhoto(
      filePath,
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
    debugPrint('BACKUP_SERVICE_UPLOAD_ERROR: $e');
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
  required Map<String, DioUploadCancelToken> activeUploads,
  required BackupLocalDataSource backupLocalDataSource,
}) async {
  final taskId = taskMap['id']! as String;
  final filePath = taskMap['file_path']! as String;
  final localAssetId = taskMap['local_asset_id'] as String?;
  
  final cancelToken = DioUploadCancelToken();
  activeUploads[taskId] = cancelToken;

  await db.update(
    'upload_tasks',
    {'status': UploadStatus.uploading.name},
    where: 'id = ?',
    whereArgs: [taskId],
  );
  service.invoke('update', {'id': taskId, 'status': 'uploading'});

  final result = await repository.uploadPhoto(
    filePath,
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
  final uploading = all.where((e) => e.status == 'uploading').length;
  final queued = all.where((e) => e.status == 'queued' || e.status == 'failed').length;

  final itemsLeft = queued + uploading;

  if (itemsLeft == 0) {
    if (service is AndroidServiceInstance) {
      await service.setAsBackgroundService();
    }

    final synced = all.where((e) => e.status == 'synced').length;
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
