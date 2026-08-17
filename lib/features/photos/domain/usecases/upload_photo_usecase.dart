import 'dart:io';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class UploadPhotoUseCase {
  UploadPhotoUseCase(this.repository);
  final PhotoCommandRepository repository;

  Future<Either<Failure, Unit>> call(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    return repository.uploadPhoto(file, onProgress: onProgress);
  }
}
