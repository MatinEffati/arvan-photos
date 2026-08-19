import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/entities/upload_task.dart';
import 'package:arvan_photos/features/photos/domain/repositories/upload_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class EnqueueUploadUseCase {
  EnqueueUploadUseCase(this._repository);

  final UploadRepository _repository;

  Future<Either<Failure, Unit>> call(UploadTask task) {
    return _repository.addTask(task);
  }
}
