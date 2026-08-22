import 'dart:io';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract class PhotosRepository {
  Future<Either<Failure, void>> uploadPhoto(File file, String remoteKey);
  Future<Either<Failure, void>> deletePhoto(String remoteKey);
  Future<Either<Failure, List<String>>> getCloudPhotos();
}
