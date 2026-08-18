import 'package:arvan_photos/features/cloud/domain/entities/cloud_photo.dart';

abstract class CloudRepository {
  Future<List<CloudPhoto>> getPhotos();
  Future<void> deletePhoto(String key);
}
