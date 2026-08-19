import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/cloud/domain/entities/paginated_cloud_photos.dart';
import 'package:dartz/dartz.dart';

abstract class CloudRepository {
  Future<Either<Failure, PaginatedCloudPhotos>> getPhotos({String? continuationToken});
  Future<Either<Failure, Unit>> deletePhoto(String key);
}
