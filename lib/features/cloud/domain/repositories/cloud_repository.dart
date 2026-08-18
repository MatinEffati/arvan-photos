import 'package:arvan_photos/features/cloud/domain/entities/cloud_photo.dart';
import 'package:arvan_photos/features/cloud/domain/entities/paginated_cloud_photos.dart';

abstract class CloudRepository {
  Future<PaginatedCloudPhotos> getPhotos({String? continuationToken});
  Future<void> deletePhoto(String key);
}
