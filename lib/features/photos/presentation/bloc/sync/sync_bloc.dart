import 'package:arvan_photos/features/photos/domain/usecases/sync_gallery_usecase.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/sync/sync_event.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/sync/sync_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:arvan_photos/features/photos/domain/usecases/sync_gallery_usecase.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/sync/sync_event.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/sync/sync_state.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/upload/upload_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc(this._syncGalleryUseCase, this._uploadBloc) : super(SyncIdle()) {
    on<SyncRequested>(_onSyncRequested);
  }

  final SyncGalleryUseCase _syncGalleryUseCase;
  final UploadBloc _uploadBloc;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  Future<void> _onSyncRequested(
    SyncRequested event,
    Emitter<SyncState> emit,
  ) async {
    print('SYNC_LOG: Bloc received SyncRequested');
    if (_isSyncing) {
      print('SYNC_LOG: Already syncing, ignoring request');
      return;
    }

    _isSyncing = true;
    emit(const SyncInProgress(current: 0, total: 0));

    final result = await _syncGalleryUseCase();

    result.fold(
      (failure) => emit(SyncFailure(failure.message)),
      (_) {
        // Trigger UploadBloc to start background service for the new tasks
        _uploadBloc.add(UploadStatusRequested());
        emit(SyncCompleted());
      },
    );

    _isSyncing = false;
  }
}
