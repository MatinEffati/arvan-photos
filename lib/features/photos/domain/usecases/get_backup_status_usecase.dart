import 'package:arvan_photos/features/photos/domain/entities/backup_status.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetBackupStatusUseCase {
  GetBackupStatusUseCase(this._repository);
  final PhotoCommandRepository _repository;

  Future<List<BackupStatus>> call() {
    return _repository.getAllBackupStatuses();
  }
}
