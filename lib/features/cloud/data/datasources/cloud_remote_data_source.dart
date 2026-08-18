import 'package:arvan_photos/core/network/arvan_s3_client.dart';
import 'package:arvan_photos/features/cloud/data/models/cloud_photo_model.dart';
import 'package:arvan_photos/features/cloud/domain/entities/paginated_cloud_photos.dart';
import 'package:injectable/injectable.dart';

abstract class CloudRemoteDataSource {
  Future<PaginatedCloudPhotos> getPhotos({String? continuationToken});
  Future<void> deletePhoto(String key);
}

@LazySingleton(as: CloudRemoteDataSource)
class CloudRemoteDataSourceImpl implements CloudRemoteDataSource {
  CloudRemoteDataSourceImpl(this._client);
  final ArvanS3Client _client;

  @override
  Future<PaginatedCloudPhotos> getPhotos({String? continuationToken}) async {
    final response = await _client.listObjects(
      continuationToken: continuationToken,
      maxKeys: 50, // Smaller batch size for pagination
    );
    final photos = response.contents
        .map((element) => CloudPhotoModel.fromXmlElement(element, _client.baseUrl))
        .toList();
    
    return PaginatedCloudPhotos(
      photos: photos,
      nextContinuationToken: response.nextContinuationToken,
    );
  }

  @override
  Future<void> deletePhoto(String key) async {
    await _client.deleteObject(key);
  }
}
