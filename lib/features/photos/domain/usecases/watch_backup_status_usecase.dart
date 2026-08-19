import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class WatchBackupStatusUseCase {
  WatchBackupStatusUseCase(this._repository);
  final PhotoCommandRepository _repository;

  Stream<Map<String, dynamic>> call() {
    return _repository.watchBackupStatus();
  }
}
