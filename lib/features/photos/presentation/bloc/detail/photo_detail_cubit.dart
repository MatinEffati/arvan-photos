import 'dart:io';
import 'package:arvan_photos/features/photos/domain/usecases/delete_photo_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/edit_photo_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'photo_detail_state.dart';

@injectable
class PhotoDetailCubit extends Cubit<PhotoDetailState> {
  PhotoDetailCubit(
    this._deletePhotoUseCase,
    this._editPhotoUseCase,
  ) : super(PhotoDetailInitial());

  final DeletePhotoUseCase _deletePhotoUseCase;
  final EditPhotoUseCase _editPhotoUseCase;

  Future<void> deletePhoto(String key) async {
    emit(PhotoDetailActionInProgress());
    final result = await _deletePhotoUseCase(key);
    result.fold(
      (failure) => emit(PhotoDetailActionFailure(failure.message)),
      (_) => emit(PhotoDetailDeleteSuccess()),
    );
  }

  Future<void> editPhoto(String key, File editedFile) async {
    emit(PhotoDetailActionInProgress());
    final result = await _editPhotoUseCase(key, editedFile);
    result.fold(
      (failure) => emit(PhotoDetailActionFailure(failure.message)),
      (_) => emit(PhotoDetailEditSuccess()),
    );
  }
}
