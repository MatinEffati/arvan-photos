import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/entities/paginated_photos.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_query_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetPhotosUseCase {
  GetPhotosUseCase(this.repository);
  final PhotoQueryRepository repository;

  Future<Either<Failure, PaginatedPhotos>> call({
    String? continuationToken,
    int maxKeys = 20,
  }) async {
    return repository.getPhotos(
      continuationToken: continuationToken,
      maxKeys: maxKeys,
    );
  }
}
