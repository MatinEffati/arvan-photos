import 'package:injectable/injectable.dart';
import 'package:photo_manager/photo_manager.dart';

// ignore_for_file: one_member_abstracts
abstract class DeviceGalleryDataSource {
  Future<List<AssetEntity>> getLocalAssets();
}

@LazySingleton(as: DeviceGalleryDataSource)
class DeviceGalleryDataSourceImpl implements DeviceGalleryDataSource {
  @override
  Future<List<AssetEntity>> getLocalAssets() async {
    // درخواست مجوز - اگر قبلاً داده نشده باشد، دیالوگ باز می‌شود
    PermissionState ps = await PhotoManager.requestPermissionExtend();
    
    if (!ps.isAuth && ps != PermissionState.limited) {
      // تلاش مجدد برای باز کردن دیالوگ اگر denied است
      ps = await PhotoManager.requestPermissionExtend();
    }

    print('SYNC_LOG: Permission Final State: $ps');
    
    if (!ps.isAuth && ps != PermissionState.limited) {
      return [];
    }
    
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
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
    
    for (var asset in assets) {
      print('DEBUG_GALLERY: Found asset ID: ${asset.id}, Name: ${asset.title}');
    }
    
    return assets;
  }
}
