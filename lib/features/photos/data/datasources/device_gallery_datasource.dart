import 'package:injectable/injectable.dart';
import 'package:photo_manager/photo_manager.dart';

abstract class DeviceGalleryDataSource {
  Future<List<AssetEntity>> getLocalAssets();
}

@LazySingleton(as: DeviceGalleryDataSource)
class DeviceGalleryDataSourceImpl implements DeviceGalleryDataSource {
  @override
  Future<List<AssetEntity>> getLocalAssets() async {
    var ps = await PhotoManager.requestPermissionExtend();
    
    if (!ps.isAuth && ps != PermissionState.limited) {
      ps = await PhotoManager.requestPermissionExtend();
    }


    if (!ps.isAuth && ps != PermissionState.limited) {
      return [];
    }
    
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    
    if (paths.isEmpty) return [];
    
    final allAlbum = paths.first;
    final count = await allAlbum.assetCountAsync;

    final assets = await allAlbum.getAssetListRange(
      start: 0,
      end: count,
    );
    
    return assets;
  }
}
