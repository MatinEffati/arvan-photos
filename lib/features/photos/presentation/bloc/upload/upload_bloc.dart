import 'dart:io';
import 'package:arvan_photos/features/photos/domain/usecases/upload_photo_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'upload_event.dart';
part 'upload_state.dart';

@injectable
class UploadBloc extends Bloc<UploadEvent, UploadState> {
  UploadBloc(this._uploadPhotoUseCase) : super(UploadInitial()) {
    on<UploadStarted>(_onUploadStarted);
    on<UploadProgressUpdated>(_onUploadProgressUpdated);
  }

  final UploadPhotoUseCase _uploadPhotoUseCase;

  Future<void> _onUploadStarted(
    UploadStarted event,
    Emitter<UploadState> emit,
  ) async {
    final totalFiles = event.files.length;
    emit(UploadInProgress(0, totalFiles: totalFiles, currentFileIndex: 0));

    for (var i = 0; i < totalFiles; i++) {
      final file = event.files[i];
      final result = await _uploadPhotoUseCase(
        file,
        onProgress: (fileProgress) {
          add(UploadProgressUpdated(
            progress: (i + fileProgress) / totalFiles,
            currentFileIndex: i,
          ));
        },
      );

      if (result.isLeft()) {
        result.fold(
          (failure) => emit(UploadFailure(failure.message)),
          (_) => null,
        );
        return;
      }
    }

    emit(UploadSuccess());
  }

  void _onUploadProgressUpdated(
    UploadProgressUpdated event,
    Emitter<UploadState> emit,
  ) {
    if (state is UploadInProgress) {
      final current = state as UploadInProgress;
      emit(UploadInProgress(
        event.progress,
        totalFiles: current.totalFiles,
        currentFileIndex: event.currentFileIndex,
      ));
    }
  }
}
