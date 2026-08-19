import 'package:arvan_photos/features/photos/data/datasources/device_gallery_datasource.dart';
import 'package:arvan_photos/features/photos/domain/entities/device_asset.dart';
import 'package:arvan_photos/features/photos/domain/repositories/device_gallery_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:photo_manager/photo_manager.dart';

@LazySingleton(as: DeviceGalleryRepository)
class DeviceGalleryRepositoryImpl implements DeviceGalleryRepository {
  DeviceGalleryRepositoryImpl(this._dataSource);
  final DeviceGalleryDataSource _dataSource;

  @override
  Future<List<DeviceAsset>> getAssets() async {
    final assets = await _dataSource.getLocalAssets();
    return assets.map((a) => DeviceAsset(
      id: a.id,
      modifiedDateTime: a.modifiedDateTime,
      title: a.title,
      width: a.width,
      height: a.height,
      duration: Duration(seconds: a.duration),
    )).toList();
  }

  @override
  Future<String?> getAssetPath(String id) async {
    final asset = await AssetEntity.fromId(id);
    final file = await asset?.file;
    return file?.path;
  }
}
