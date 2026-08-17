import 'dart:io';

import 'package:arvan_photos/core/error/error_mapper.dart';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/data/datasources/photo_key_generator.dart';
import 'package:arvan_photos/features/photos/data/datasources/photos_remote_data_source.dart';
import 'package:arvan_photos/features/photos/domain/entities/paginated_photos.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_query_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PhotoRepositoryImpl
    implements PhotoQueryRepository, PhotoCommandRepository {
  PhotoRepositoryImpl(this.remoteDataSource, this.keyGenerator);

  final PhotosRemoteDataSource remoteDataSource;
  final PhotoKeyGenerator keyGenerator;

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
  Future<Either<Failure, Unit>> uploadPhoto(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final key = keyGenerator.generateKey(file.path);
      
      await remoteDataSource.uploadPhoto(
        key, 
        file,
        onProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );
      return const Right(unit);
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
  Future<Either<Failure, Unit>> editPhoto(String key, File editedFile) async {
    try {
      await remoteDataSource.uploadPhoto(key, editedFile);
      return const Right(unit);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}
