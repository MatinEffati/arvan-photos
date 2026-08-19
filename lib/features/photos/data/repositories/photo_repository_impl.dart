import 'dart:async';
import 'dart:io';

import 'package:arvan_photos/core/error/error_mapper.dart';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/core/network/dio_upload_cancel_token.dart';
import 'package:arvan_photos/core/services/app_background_service.dart';
import 'package:arvan_photos/features/cloud/data/datasources/cloud_remote_data_source.dart';
import 'package:arvan_photos/features/photos/data/datasources/backup_local_datasource.dart';
import 'package:arvan_photos/features/photos/data/datasources/photo_key_generator.dart';
import 'package:arvan_photos/features/photos/domain/entities/backup_status.dart';
import 'package:arvan_photos/features/photos/domain/entities/upload_cancel_token.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_query_repository.dart';
import 'package:dartz/dartz.dart';
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

  @override
  Future<Either<Failure, String>> uploadPhoto(
    String filePath, {
    void Function(double progress)? onProgress,
    UploadCancelToken? cancelToken,
  }) async {
    try {
      final key = keyGenerator.generateKey(filePath);
      final file = File(filePath);
      
      final dioToken = cancelToken is DioUploadCancelToken ? cancelToken.dioToken : null;
      
      await remoteDataSource.uploadPhoto(
        key, 
        file,
        cancelToken: dioToken,
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
      await backupLocalDataSource.enqueue(assets);
      
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      
      if (!isRunning) {
        await AppBackgroundService.start();
      } else {
        service.invoke('enqueue');
      }
      
      return const Right(unit);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteBackup(List<String> assetIds) async {
    try {
      for (final id in assetIds) {
        final statusItem = await backupLocalDataSource.getById(id);
        if (statusItem != null && statusItem.remoteKey != null) {
          final key = statusItem.remoteKey!;
          await remoteDataSource.deletePhoto(key);
          await backupLocalDataSource.updateStatus(id, 'manually_removed');
          _statusController.add({'assetId': id, 'status': 'manually_removed'});
        }
      }
      return const Right(unit);
    } catch (e) {
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
    final items = await backupLocalDataSource.getAll();
    return items.map((e) => BackupStatus(
      assetId: e.localAssetId,
      status: e.status,
      progress: e.progress,
      remoteKey: e.remoteKey,
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
