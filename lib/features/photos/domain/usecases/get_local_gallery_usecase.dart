import 'package:arvan_photos/features/photos/domain/entities/device_asset.dart';
import 'package:arvan_photos/features/photos/domain/repositories/device_gallery_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetLocalGalleryUseCase {
  GetLocalGalleryUseCase(this._repository);
  final DeviceGalleryRepository _repository;

  Future<List<DeviceAsset>> call() {
    return _repository.getAssets();
  }
}
