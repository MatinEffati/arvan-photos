import 'package:arvan_photos/core/error/error_mapper.dart';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/data/datasources/device_gallery_datasource.dart';
import 'package:arvan_photos/features/photos/domain/entities/device_asset.dart';
import 'package:arvan_photos/features/photos/domain/repositories/device_gallery_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: DeviceGalleryRepository)
class DeviceGalleryRepositoryImpl implements DeviceGalleryRepository {
  DeviceGalleryRepositoryImpl(this._dataSource);

  final DeviceGalleryDataSource _dataSource;

  @override
  Future<Either<Failure, List<DeviceAsset>>> getLocalAssets() async {
    try {
      final assets = await _dataSource.getLocalAssets();
      final deviceAssets = assets.map((a) => DeviceAsset(
        id: a.id,
        modifiedDateTime: a.modifiedDateTime,
        width: a.width,
        height: a.height,
        duration: a.duration,
        typeInt: a.typeInt,
      )).toList();
      return Right(deviceAssets);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}
