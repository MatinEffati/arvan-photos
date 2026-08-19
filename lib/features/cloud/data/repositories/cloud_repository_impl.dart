import 'package:arvan_photos/core/error/error_mapper.dart';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/cloud/data/datasources/cloud_remote_data_source.dart';
import 'package:arvan_photos/features/cloud/domain/entities/paginated_cloud_photos.dart';
import 'package:arvan_photos/features/cloud/domain/repositories/cloud_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CloudRepository)
class CloudRepositoryImpl implements CloudRepository {
  CloudRepositoryImpl(this._remoteDataSource);
  final CloudRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, PaginatedCloudPhotos>> getPhotos({String? continuationToken}) async {
    try {
      final result = await _remoteDataSource.getPhotos(continuationToken: continuationToken);
      return Right(result);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePhoto(String key) async {
    try {
      await _remoteDataSource.deletePhoto(key);
      return const Right(unit);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}
