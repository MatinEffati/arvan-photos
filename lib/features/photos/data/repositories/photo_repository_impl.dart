import 'dart:io';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/data/datasources/arvan_s3_client.dart';
import 'package:arvan_photos/features/photos/data/models/photo_model.dart';
import 'package:arvan_photos/features/photos/domain/entities/photo_entity.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

@LazySingleton(as: PhotoRepository)
class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl(this.s3client);
  final ArvanS3Client s3client;
  final _uuid = const Uuid();

  @override
  Future<Either<Failure, List<PhotoEntity>>> getPhotos() async {
    try {
      final elements = await s3client.listObjects();
      final photos = elements
          .map((e) => PhotoModel.fromXmlElement(e, s3client.baseUrl))
          .toList();
      return Right(photos);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePhoto(String key) async {
    try {
      await s3client.deleteObject(key);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> editPhoto(String key, File editedFile) async {
    try {
      await s3client.putObject(key, editedFile);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
