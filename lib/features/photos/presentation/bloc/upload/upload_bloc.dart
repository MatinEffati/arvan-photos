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
  }

  final UploadPhotoUseCase _uploadPhotoUseCase;

  Future<void> _onUploadStarted(
    UploadStarted event,
    Emitter<UploadState> emit,
  ) async {
    emit(const UploadInProgress(0));
    final result = await _uploadPhotoUseCase(event.file);
    result.fold(
      (failure) => emit(UploadFailure(failure.message)),
      (_) => emit(UploadSuccess()),
    );
  }
}
