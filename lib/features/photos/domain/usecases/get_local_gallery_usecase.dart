import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/entities/device_asset.dart';
import 'package:arvan_photos/features/photos/domain/repositories/device_gallery_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetLocalGalleryUseCase {
  GetLocalGalleryUseCase(this._repository);

  final DeviceGalleryRepository _repository;

  Future<Either<Failure, List<DeviceAsset>>> call() {
    return _repository.getLocalAssets();
  }
}
