import 'dart:async';
import 'dart:io';

import 'package:arvan_photos/core/error/error_mapper.dart';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/core/services/app_background_service.dart';
import 'package:arvan_photos/features/photos/data/datasources/backup_local_datasource.dart';
import 'package:arvan_photos/features/photos/data/datasources/photo_key_generator.dart';
import 'package:arvan_photos/features/photos/data/datasources/photos_remote_data_source.dart';
import 'package:arvan_photos/features/photos/domain/entities/paginated_photos.dart';
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

  final PhotosRemoteDataSource remoteDataSource;
  final PhotoKeyGenerator keyGenerator;
  final BackupLocalDataSource backupLocalDataSource;

  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _backgroundSub;

  @override
  Future<Either<Failure, PaginatedPhotos>> getPhotos({
    String? continuationToken,
    int maxKeys = 20,
  }) async {
    try {
      final response = await remoteDataSource.getPhotos(
        continuationToken: continuationToken,
        maxKeys: maxKeys,
      );

      return Right(
        PaginatedPhotos(
          photos: response.photos,
          nextContinuationToken: response.nextToken,
        ),
      );
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, String>> uploadPhoto(
    File file, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final key = keyGenerator.generateKey(file.path);
      
      await remoteDataSource.uploadPhoto(
        key, 
        file,
        cancelToken: cancelToken,
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
      // Removed syncLocalDataSource dependency. 
      // If we need to mark as deleted in backup_queue, we should add a method to BackupLocalDataSource.
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
  Future<Either<Failure, Unit>> editPhoto(String key, File editedFile) async {
    try {
      await remoteDataSource.uploadPhoto(key, editedFile);
      return const Right(unit);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> enqueueBackup(List<String> assetIds) async {
    try {
      await backupLocalDataSource.enqueue(assetIds);
      AppBackgroundService.start();
      FlutterBackgroundService().invoke('enqueue');
      return const Right(unit);
    } catch (e) {
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
  Future<List<Map<String, dynamic>>> getAllBackupStatuses() async {
    return backupLocalDataSource.getAll();
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
