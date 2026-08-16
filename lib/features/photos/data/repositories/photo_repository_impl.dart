import 'dart:io';
import 'package:arvan_photos/core/error/error_mapper.dart';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/data/datasources/arvan_s3_client.dart';
import 'package:arvan_photos/features/photos/data/models/photo_model.dart';
import 'package:arvan_photos/features/photos/domain/entities/paginated_photos.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_query_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

@lazySingleton
class PhotoRepositoryImpl implements PhotoQueryRepository, PhotoCommandRepository {
  PhotoRepositoryImpl(this.s3client);
  final ArvanS3Client s3client;
  final _uuid = const Uuid();

  @override
  Future<Either<Failure, PaginatedPhotos>> getPhotos({
    String? continuationToken,
    int maxKeys = 20,
  }) async {
    try {
      final response = await s3client.listObjects(
        continuationToken: continuationToken,
        maxKeys: maxKeys,
      );
      final photos = response.contents
          .map((e) => PhotoModel.fromXmlElement(e, s3client.baseUrl))
          .toList();
      
      return Right(PaginatedPhotos(
        photos: photos,
        nextContinuationToken: response.nextContinuationToken,
      ));
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> uploadPhoto(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final extension = fileName.split('.').last;
      final key = 'photos/${_uuid.v4()}.$extension';
      await s3client.putObject(key, file);
      return const Right(unit);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePhoto(String key) async {
    try {
      await s3client.deleteObject(key);
      return const Right(unit);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMultiplePhotos(List<String> keys) async {
    try {
      for (final key in keys) {
        await s3client.deleteObject(key);
      }
      return const Right(unit);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> editPhoto(String key, File editedFile) async {
    try {
      await s3client.putObject(key, editedFile);
      return const Right(unit);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}
