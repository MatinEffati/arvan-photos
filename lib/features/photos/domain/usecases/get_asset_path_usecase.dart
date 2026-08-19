import 'package:arvan_photos/features/photos/domain/repositories/device_gallery_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetAssetPathUseCase {
  GetAssetPathUseCase(this._repository);
  final DeviceGalleryRepository _repository;

  Future<String?> call(String id) {
    return _repository.getAssetPath(id);
  }
}
