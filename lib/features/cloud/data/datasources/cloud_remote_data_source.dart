import 'package:arvan_photos/core/network/arvan_s3_client.dart';
import 'package:arvan_photos/features/cloud/data/models/cloud_photo_model.dart';
import 'package:injectable/injectable.dart';

abstract class CloudRemoteDataSource {
  Future<List<CloudPhotoModel>> getPhotos();
  Future<void> deletePhoto(String key);
}

@LazySingleton(as: CloudRemoteDataSource)
class CloudRemoteDataSourceImpl implements CloudRemoteDataSource {
  CloudRemoteDataSourceImpl(this._client);
  final ArvanS3Client _client;

  @override
  Future<List<CloudPhotoModel>> getPhotos() async {
    final response = await _client.listObjects(maxKeys: 1000);
    return response.contents
        .map((element) => CloudPhotoModel.fromXmlElement(element, _client.baseUrl))
        .toList();
  }

  @override
  Future<void> deletePhoto(String key) async {
    await _client.deleteObject(key);
  }
}
