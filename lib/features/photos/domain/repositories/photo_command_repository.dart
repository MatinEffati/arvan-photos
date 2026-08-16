import 'dart:io';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract class PhotoCommandRepository {
  Future<Either<Failure, Unit>> uploadPhoto(File file);
  Future<Either<Failure, Unit>> deletePhoto(String key);
  Future<Either<Failure, Unit>> deleteMultiplePhotos(List<String> keys);
  Future<Either<Failure, Unit>> editPhoto(String key, File editedFile);
}
