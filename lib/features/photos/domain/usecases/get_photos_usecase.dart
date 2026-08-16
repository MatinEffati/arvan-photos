import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/entities/photo_entity.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetPhotosUseCase {
  GetPhotosUseCase(this.repository);
  final PhotoRepository repository;

  Future<Either<Failure, List<PhotoEntity>>> call() async {
    return repository.getPhotos();
  }
}
