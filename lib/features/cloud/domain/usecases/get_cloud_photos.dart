import 'package:arvan_photos/features/cloud/domain/entities/cloud_photo.dart';
import 'package:arvan_photos/features/cloud/domain/repositories/cloud_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GetCloudPhotos {
  GetCloudPhotos(this._repository);
  final CloudRepository _repository;

  Future<List<CloudPhoto>> call() {
    return _repository.getPhotos();
  }
}
