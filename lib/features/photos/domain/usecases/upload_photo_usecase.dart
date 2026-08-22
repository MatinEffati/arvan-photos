import 'dart:io';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photos_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class UploadPhotoUseCase {
  UploadPhotoUseCase(this._repository);

  final PhotosRepository _repository;

  Future<Either<Failure, void>> call(
    File file,
    String remoteKey, {
    void Function(int sent, int total)? onProgress,
  }) {
    return _repository.uploadPhoto(file, remoteKey, onProgress: onProgress);
  }
}
