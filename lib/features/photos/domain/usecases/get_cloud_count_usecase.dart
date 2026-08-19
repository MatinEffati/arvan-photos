import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_query_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetCloudCountUseCase {
  GetCloudCountUseCase(this._repository);
  final PhotoQueryRepository _repository;

  Future<Either<Failure, int>> call() {
    return _repository.getCloudCount();
  }
}
