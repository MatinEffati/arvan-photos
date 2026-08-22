import 'dart:io';
import 'package:arvan_photos/core/error/error_mapper.dart';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/data/datasources/photos_remote_data_source.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photos_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PhotosRepository)
class PhotosRepositoryImpl implements PhotosRepository {
  PhotosRepositoryImpl(this._remoteDataSource);

  final PhotosRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, void>> uploadPhoto(
    File file,
    String remoteKey, {
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      await _remoteDataSource.uploadPhoto(file, remoteKey, onProgress: onProgress);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> deletePhoto(String remoteKey) async {
    try {
      await _remoteDataSource.deletePhoto(remoteKey);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getCloudPhotos() async {
    try {
      final photos = await _remoteDataSource.listPhotos();
      return Right(photos);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}
