import 'dart:io';
import 'package:arvan_photos/features/photos/data/datasources/photos_local_data_source.dart';
import 'package:arvan_photos/features/photos/domain/usecases/get_asset_path_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/upload_photo_usecase.dart';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

part 'upload_event.dart';
part 'upload_state.dart';

@injectable
class UploadBloc extends Bloc<UploadEvent, UploadState> {
  UploadBloc(
    this._uploadPhoto,
    this._getAssetPath,
    this._localDataSource,
  ) : super(UploadInitial()) {
    on<UploadPhotoRequested>(_onUploadRequested);
  }

  final UploadPhotoUseCase _uploadPhoto;
  final GetAssetPathUseCase _getAssetPath;
  final PhotosLocalDataSource _localDataSource;
  static const _uuid = Uuid();

  Future<void> _onUploadRequested(
    UploadPhotoRequested event,
    Emitter<UploadState> emit,
  ) async {
    emit(UploadInProgress(event.assetId));
    
    final path = await _getAssetPath(event.assetId);
    if (path == null) {
      emit(UploadFailure(event.assetId, 'File not found on device'));
      return;
    }

    final file = File(path);
    final extension = p.extension(path);
    final originalFilename = p.basename(path);
    final remoteKey = 'photos/${_uuid.v4()}$extension';
    
    final result = await _uploadPhoto(file, remoteKey);
    
    await result.fold(
      (failure) async => emit(UploadFailure(event.assetId, failure.message)),
      (_) async {
        await _localDataSource.registerBackup(
          assetId: event.assetId,
          remoteKey: remoteKey,
          originalFilename: originalFilename,
        );
        emit(UploadSuccess(event.assetId));
      },
    );
  }
}
