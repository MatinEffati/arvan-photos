import 'package:arvan_photos/features/cloud/data/datasources/cloud_remote_data_source.dart';
import 'package:arvan_photos/features/cloud/domain/entities/paginated_cloud_photos.dart';
import 'package:arvan_photos/features/cloud/domain/repositories/cloud_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CloudRepository)
class CloudRepositoryImpl implements CloudRepository {
  CloudRepositoryImpl(this._remoteDataSource);
  final CloudRemoteDataSource _remoteDataSource;

  @override
  Future<PaginatedCloudPhotos> getPhotos({String? continuationToken}) {
    return _remoteDataSource.getPhotos(continuationToken: continuationToken);
  }

  @override
  Future<void> deletePhoto(String key) {
    return _remoteDataSource.deletePhoto(key);
  }
}
