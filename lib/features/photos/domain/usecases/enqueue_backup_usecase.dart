import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class EnqueueBackupUseCase {
  const EnqueueBackupUseCase(this._repository);

  final PhotoCommandRepository _repository;

  Future<Either<Failure, Unit>> call(List<Map<String, String>> assets) async {
    return _repository.enqueueBackup(assets);
  }
}
