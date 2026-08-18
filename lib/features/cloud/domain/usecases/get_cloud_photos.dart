import 'package:arvan_photos/features/cloud/domain/entities/paginated_cloud_photos.dart';
import 'package:arvan_photos/features/cloud/domain/repositories/cloud_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GetCloudPhotos {
  GetCloudPhotos(this._repository);
  final CloudRepository _repository;

  Future<PaginatedCloudPhotos> call({String? continuationToken}) {
    return _repository.getPhotos(continuationToken: continuationToken);
  }
}
