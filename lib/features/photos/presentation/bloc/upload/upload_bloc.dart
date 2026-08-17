import 'dart:io';
import 'package:arvan_photos/features/photos/domain/entities/upload_task.dart';
import 'package:arvan_photos/features/photos/domain/usecases/upload_photo_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

part 'upload_event.dart';
part 'upload_state.dart';

@injectable
class UploadBloc extends Bloc<UploadEvent, UploadState> {
  UploadBloc(this._uploadPhotoUseCase) : super(UploadInitial()) {
    on<UploadStarted>(_onUploadStarted);
    on<UploadTaskUpdated>(_onUploadTaskUpdated);
    on<UploadResetRequested>(_onUploadResetRequested);
  }

  final UploadPhotoUseCase _uploadPhotoUseCase;
  final _uuid = const Uuid();
  bool _isProcessing = false;

  void _onUploadResetRequested(
    UploadResetRequested event,
    Emitter<UploadState> emit,
  ) {
    _isProcessing = false;
    emit(UploadInitial());
  }

  Future<void> _onUploadStarted(
    UploadStarted event,
    Emitter<UploadState> emit,
  ) async {
    final newTasks = event.files.map((file) => UploadTask(
      id: _uuid.v4(),
      file: file,
      status: UploadStatus.pending,
    )).toList();

    List<UploadTask> currentTasks = [];
    if (state is UploadInProgress) {
      currentTasks = List.from((state as UploadInProgress).tasks);
    }
    currentTasks.addAll(newTasks);

    emit(UploadInProgress(tasks: currentTasks));

    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (true) {
        final currentState = state;
        if (currentState is! UploadInProgress) break;

        final pendingIndex = currentState.tasks.indexWhere((t) => t.status == UploadStatus.pending);
        if (pendingIndex == -1) break;

        var task = currentState.tasks[pendingIndex];
        add(UploadTaskUpdated(task.copyWith(status: UploadStatus.uploading)));

        final result = await _uploadPhotoUseCase(
          task.file,
          onProgress: (progress) {
            add(UploadTaskUpdated(task.copyWith(status: UploadStatus.uploading, progress: progress)));
          },
        );

        result.fold(
          (failure) {
            add(UploadTaskUpdated(task.copyWith(status: UploadStatus.failure, errorMessage: failure.message, progress: 0.0)));
          },
          (_) {
            add(UploadTaskUpdated(task.copyWith(status: UploadStatus.success, progress: 1.0)));
          },
        );
        
        // Brief delay between uploads to let the UI breathe
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      _isProcessing = false;
    }

    // Check final status
    final latestState = state;
    if (latestState is UploadInProgress) {
      final allFinished = latestState.tasks.every((t) => t.status == UploadStatus.success || t.status == UploadStatus.failure);
      if (allFinished) {
        final allSuccess = latestState.tasks.every((t) => t.status == UploadStatus.success);
        if (allSuccess) {
          emit(UploadSuccess());
        } else {
          emit(const UploadFailure('Some files failed to upload'));
        }
      }
    }
  }

  void _onUploadTaskUpdated(
    UploadTaskUpdated event,
    Emitter<UploadState> emit,
  ) {
    if (state is UploadInProgress) {
      final tasks = List<UploadTask>.from((state as UploadInProgress).tasks);
      final index = tasks.indexWhere((t) => t.id == event.task.id);
      if (index != -1) {
        tasks[index] = event.task;
        emit(UploadInProgress(tasks: tasks));
      }
    }
  }
}
