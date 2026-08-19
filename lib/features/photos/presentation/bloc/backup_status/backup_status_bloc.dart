import 'dart:async';

import 'package:arvan_photos/features/photos/domain/entities/backup_status.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_event.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class BackupStatusBloc extends Bloc<BackupStatusEvent, BackupStatusState> {
  BackupStatusBloc(this._repository) : super(const BackupStatusState()) {
    on<BackupStatusStarted>(_onStarted);
    on<BackupStatusUpdated>(_onUpdated);
  }

  final PhotoCommandRepository _repository;
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;

  Future<void> _onStarted(
    BackupStatusStarted event,
    Emitter<BackupStatusState> emit,
  ) async {
    // Initial load of all statuses from DB
    final initialStatuses = await _repository.getAllBackupStatuses();
    final Map<String, BackupStatus> statusMap = {};
    for (final status in initialStatuses) {
      statusMap[status.assetId] = status;
    }
    emit(state.copyWith(statuses: statusMap));

    // Start watching for real-time updates from background service
    await _statusSubscription?.cancel();
    _statusSubscription = _repository.watchBackupStatus().listen((status) {
      add(BackupStatusUpdated(status));
    });
  }

  void _onUpdated(
    BackupStatusUpdated event,
    Emitter<BackupStatusState> emit,
  ) {
    final assetId = event.status['assetId'] as String?;
    if (assetId == null) return;

    final updatedStatuses = Map<String, BackupStatus>.from(state.statuses);
    
    // Merge new status info into existing entry
    final status = event.status['status'] as String;
    final progress = (event.status['progress'] as num?)?.toDouble() ?? 0.0;
    final remoteKey = event.status['remoteKey'] as String?;

    updatedStatuses[assetId] = BackupStatus(
      assetId: assetId,
      status: status,
      progress: progress,
      remoteKey: remoteKey ?? updatedStatuses[assetId]?.remoteKey,
    );

    emit(state.copyWith(statuses: updatedStatuses));
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
}
