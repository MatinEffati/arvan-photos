import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/entities/paginated_photos.dart';
import 'package:dartz/dartz.dart';

abstract class PhotoQueryRepository {
  Future<Either<Failure, PaginatedPhotos>> getPhotos({
    String? continuationToken,
    int maxKeys = 20,
  });
}
