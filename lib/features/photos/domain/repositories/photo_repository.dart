import 'dart:io';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/entities/photo_entity.dart';
import 'package:dartz/dartz.dart';

abstract class PhotoRepository {
  Future<Either<Failure, List<PhotoEntity>>> getPhotos();
  Future<Either<Failure, Unit>> uploadPhoto(File file);
  Future<Either<Failure, Unit>> deletePhoto(String key);
  Future<Either<Failure, Unit>> deleteMultiplePhotos(List<String> keys);
  Future<Either<Failure, Unit>> editPhoto(String key, File editedFile);
}
