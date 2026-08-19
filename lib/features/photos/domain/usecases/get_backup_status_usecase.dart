import 'package:arvan_photos/features/photos/domain/entities/backup_status.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetBackupStatusUseCase {
  GetBackupStatusUseCase(this._repository);

  final PhotoCommandRepository _repository;

  Stream<BackupStatus> watch() {
    return _repository.watchBackupStatus().map((event) => BackupStatus(
      assetId: event['assetId'] as String,
      status: event['status'] as String,
      progress: (event['progress'] as num?)?.toDouble() ?? 0.0,
      remoteKey: event['remoteKey'] as String?,
    ));
  }

  Future<List<BackupStatus>> getAll() async {
    final statuses = await _repository.getAllBackupStatuses();
    return statuses.map((event) => BackupStatus(
      assetId: event['local_asset_id'] as String,
      status: event['status'] as String,
      progress: (event['progress'] as num?)?.toDouble() ?? 0.0,
      remoteKey: event['remote_key'] as String?,
    )).toList();
  }

  Future<List<String>> getSyncedIds() {
    return _repository.getSyncedIds();
  }
}
