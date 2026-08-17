import 'dart:io';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:dartz/dartz.dart';

import 'package:dio/dio.dart';

abstract class PhotoCommandRepository {
  Future<Either<Failure, Unit>> uploadPhoto(
    File file, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  });
  Future<Either<Failure, Unit>> deletePhoto(String key);
  Future<Either<Failure, Unit>> deleteMultiplePhotos(List<String> keys);
  Future<Either<Failure, Unit>> editPhoto(String key, File editedFile);
}
