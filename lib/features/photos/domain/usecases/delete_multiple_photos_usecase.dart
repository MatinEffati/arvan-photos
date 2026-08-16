import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteMultiplePhotosUseCase {
  DeleteMultiplePhotosUseCase(this.repository);
  final PhotoRepository repository;

  Future<Either<Failure, Unit>> call(List<String> keys) async {
    return repository.deleteMultiplePhotos(keys);
  }
}
