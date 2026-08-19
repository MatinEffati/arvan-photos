import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/entities/device_asset.dart';
import 'package:dartz/dartz.dart';

abstract class DeviceGalleryRepository {
  Future<Either<Failure, List<DeviceAsset>>> getLocalAssets();
}
