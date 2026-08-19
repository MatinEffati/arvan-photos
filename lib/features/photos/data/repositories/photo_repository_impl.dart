import 'dart:async';
import 'dart:io';

import 'package:arvan_photos/core/error/error_mapper.dart';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/core/services/app_background_service.dart';
import 'package:arvan_photos/features/cloud/data/datasources/cloud_remote_data_source.dart';
import 'package:arvan_photos/features/photos/data/datasources/backup_local_datasource.dart';
import 'package:arvan_photos/features/photos/data/datasources/photo_key_generator.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_query_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PhotoRepositoryImpl
    implements PhotoQueryRepository, PhotoCommandRepository {
  PhotoRepositoryImpl(
    this.remoteDataSource,
    this.keyGenerator,
    this.backupLocalDataSource,
  );

  final CloudRemoteDataSource remoteDataSource;
  final PhotoKeyGenerator keyGenerator;
  final BackupLocalDataSource backupLocalDataSource;

  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _backgroundSub;

  @override
  Future<Either<Failure, String>> uploadPhoto(
    String filePath, {
    void Function(double progress)? onProgress,
    dynamic cancelToken,
  }) async {
    try {
      final key = keyGenerator.generateKey(filePath);
      final file = File(filePath);
      
      await remoteDataSource.uploadPhoto(
        key, 
        file,
        cancelToken: cancelToken is CancelToken ? cancelToken : null,
        onProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );
      return Right(key);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePhoto(String key) async {
    try {
      await remoteDataSource.deletePhoto(key);
      return const Right(unit);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMultiplePhotos(List<String> keys) async {
    try {
      for (final key in keys) {
        await remoteDataSource.deletePhoto(key);
      }
      return const Right(unit);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> editPhoto(String key, String editedFilePath) async {
    try {
      await remoteDataSource.uploadPhoto(key, File(editedFilePath));
      return const Right(unit);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> enqueueBackup(List<Map<String, String>> assets) async {
    try {
      print('REPOSITORY: Enqueuing ${assets.length} assets for backup');
      await backupLocalDataSource.enqueue(assets);
      
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      print('REPOSITORY: Background service isRunning: $isRunning');
      
      if (!isRunning) {
        print('REPOSITORY: Starting background service...');
        await AppBackgroundService.start();
      } else {
        print('REPOSITORY: Sending enqueue signal to active service');
        service.invoke('enqueue');
      }
      
      return const Right(unit);
    } catch (e) {
      print('REPOSITORY_ERROR: $e');
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteBackup(List<String> assetIds) async {
    try {
      print('DEBUG_DELETE: Starting deletion for ${assetIds.length} assets');
      for (final id in assetIds) {
        final statusMap = await backupLocalDataSource.getById(id);
        if (statusMap != null && statusMap['remote_key'] != null) {
          final key = statusMap['remote_key'] as String;
          print('DEBUG_DELETE: Deleting from cloud: $key');
          await remoteDataSource.deletePhoto(key);
          await backupLocalDataSource.updateStatus(id, 'manually_removed');
          _statusController.add({'assetId': id, 'status': 'manually_removed'});
        } else {
          print('DEBUG_DELETE: Asset $id not found or has no remote key');
        }
      }
      return const Right(unit);
    } catch (e) {
      print('DEBUG_DELETE: Error occurred: $e');
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Stream<Map<String, dynamic>> watchBackupStatus() {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    
    final bgSub = FlutterBackgroundService().on('status_update').listen((e) {
      if (e != null && !controller.isClosed) controller.add(e);
    });

    final fgSub = _statusController.stream.listen((e) {
      if (!controller.isClosed) controller.add(e);
    });

    controller.onCancel = () {
      bgSub.cancel();
      fgSub.cancel();
    };

    return controller.stream;
  }

  @override
  Future<List<BackupStatus>> getAllBackupStatuses() async {
    final statuses = await backupLocalDataSource.getAll();
    return statuses.map((e) => BackupStatus(
      assetId: e['local_asset_id'] as String,
      status: e['status'] as String,
      progress: (e['progress'] as num?)?.toDouble() ?? 0.0,
      remoteKey: e['remote_key'] as String?,
    )).toList();
  }

  @override
  Future<List<String>> getSyncedIds() {
    return backupLocalDataSource.getSyncedIds();
  }

  @override
  Future<Either<Failure, int>> getCloudCount() async {
    try {
      final count = await remoteDataSource.getCloudCount();
      return Right(count);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}
