import 'package:arvan_photos/features/photos/domain/entities/device_asset.dart';

abstract class DeviceGalleryRepository {
  Future<List<DeviceAsset>> getAssets();
  Future<String?> getAssetPath(String id);
}
