import 'dart:io';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:dartz/dartz.dart';

import 'package:dio/dio.dart';

abstract class PhotoCommandRepository {
  Future<Either<Failure, String>> uploadPhoto(
    File file, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  });
  Future<Either<Failure, Unit>> deletePhoto(String key);
  Future<Either<Failure, Unit>> deleteMultiplePhotos(List<String> keys);
  Future<Either<Failure, Unit>> editPhoto(String key, File editedFile);

  Future<Either<Failure, Unit>> enqueueBackup(List<Map<String, String>> assets);
  Future<Either<Failure, Unit>> deleteBackup(List<String> assetIds);
  Future<Either<Failure, int>> getCloudCount();
  Stream<Map<String, dynamic>> watchBackupStatus();
  Future<List<Map<String, dynamic>>> getAllBackupStatuses();
  Future<List<String>> getSyncedIds();
}
