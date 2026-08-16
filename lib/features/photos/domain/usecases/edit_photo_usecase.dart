import 'dart:io';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class EditPhotoUseCase {
  EditPhotoUseCase(this.repository);
  final PhotoRepository repository;

  Future<Either<Failure, Unit>> call(String key, File editedFile) async {
    return repository.editPhoto(key, editedFile);
  }
}
