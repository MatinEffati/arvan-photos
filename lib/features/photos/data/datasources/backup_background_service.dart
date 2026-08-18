import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:arvan_photos/core/config/app_config.dart';
import 'package:arvan_photos/core/network/arvan_s3_client.dart';
import 'package:arvan_photos/core/services/notification_service.dart';
import 'package:arvan_photos/features/photos/data/datasources/photo_key_generator.dart';
import 'package:arvan_photos/features/photos/data/datasources/photos_remote_data_source_impl.dart';
import 'package:arvan_photos/features/photos/data/datasources/backup_local_datasource.dart';
import 'package:arvan_photos/features/photos/data/repositories/photo_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sqflite/sqflite.dart';

class BackupBackgroundService {
  static const int notificationId = 999;
  static const int maxConcurrentUploads = 5;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'upload_channel',
        initialNotificationTitle: 'Backup in progress',
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

  static void start() async {
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

  final db = await _getDatabase();
  final dio = Dio();
  final config = AppConfig();
  final s3Client = ArvanS3Client(dio, config);
  final remoteDataSource = PhotosRemoteDataSourceImpl(s3Client);
  final keyGenerator = S3PhotoKeyGenerator();
  final localDataSource = BackupLocalDataSourceImpl(db);
  final syncLocalDataSource = SyncLocalDataSourceImpl(db);
  
  final repository = PhotoRepositoryImpl(
    remoteDataSource,
    keyGenerator,
    syncLocalDataSource,
    localDataSource,
  );

  bool isRunning = true;
  final activeUploads = <String, CancelToken>{};
  
  service.on('stopService').listen((event) {
    isRunning = false;
    for (var token in activeUploads.values) {
      token.cancel('Service stopped');
    }
    service.stopSelf();
  });

  service.on('enqueue').listen((event) {
    // UI just enqueued something, we might already be processing
  });

  Timer.periodic(const Duration(seconds: 2), (timer) async {
    if (!isRunning) return;

    if (activeUploads.length >= BackupBackgroundService.maxConcurrentUploads) {
      return;
    }

    final pending = await localDataSource.getPending(
      BackupBackgroundService.maxConcurrentUploads - activeUploads.length,
    );

    if (pending.isEmpty && activeUploads.isEmpty) {
      // Check if completely finished
      final all = await localDataSource.getAll();
      final total = all.length;
      final synced = all.where((e) => e['status'] == 'synced').length;
      
      if (total > 0 && synced == total) {
         await NotificationService.showUploadProgress(
            id: BackupBackgroundService.notificationId,
            title: 'Backup Complete',
            progress: 100,
            total: 100,
         );
         // Auto-stop after some time?
         service.stopSelf();
         isRunning = false;
      }
      return;
    }

    for (final task in pending) {
      final assetId = task['local_asset_id'] as String;
      if (activeUploads.containsKey(assetId)) continue;

      _startUpload(
        assetId: assetId,
        service: service,
        localDataSource: localDataSource,
        repository: repository,
        activeUploads: activeUploads,
        db: db,
      );
    }
  });
}

Future<void> _startUpload({
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
    id: BackupBackgroundService.notificationId,
    title: 'Backing up... ($synced/$total)',
    progress: (overallProgress * 100).toInt(),
    total: 100,
  );
}

Future<Database> _getDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = '$dbPath/arvan_photos.db';
  return openDatabase(path);
}
