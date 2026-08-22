import 'dart:io';
import 'package:arvan_photos/core/services/notification_service.dart';
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
  ) : super(const UploadInitial()) {
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
    final newProgressMap = Map<String, double>.from(state.progressMap);
    newProgressMap[event.assetId] = 0.0;
    
    emit(UploadInProgress(event.assetId, progressMap: newProgressMap));
    
    final path = await _getAssetPath(event.assetId);
    if (path == null) {
      newProgressMap.remove(event.assetId);
      emit(UploadFailure(event.assetId, 'File not found on device', progressMap: newProgressMap));
      return;
    }

    final file = File(path);
    final extension = p.extension(path);
    final originalFilename = p.basename(path);
    final remoteKey = 'photos/${_uuid.v4()}$extension';
    
    final notificationId = event.assetId.hashCode;
    
    final result = await _uploadPhoto(
      file, 
      remoteKey,
      onProgress: (sent, total) {
        final progress = sent / total;
        final updatedMap = Map<String, double>.from(state.progressMap);
        updatedMap[event.assetId] = progress;
        
        emit(UploadInProgress(event.assetId, progressMap: updatedMap));
        
        NotificationService.showUploadProgress(
          id: notificationId,
          title: originalFilename,
          progress: (progress * 100).toInt(),
        );
      },
    );
    
    await result.fold(
      (failure) async {
        final finalMap = Map<String, double>.from(state.progressMap);
        finalMap.remove(event.assetId);
        
        NotificationService.cancel(notificationId);
        
        emit(UploadFailure(event.assetId, failure.message, progressMap: finalMap));
      },
      (_) async {
        await _localDataSource.registerBackup(
          assetId: event.assetId,
          remoteKey: remoteKey,
          originalFilename: originalFilename,
        );
        
        final finalMap = Map<String, double>.from(state.progressMap);
        finalMap.remove(event.assetId);
        
        NotificationService.showUploadProgress(
          id: notificationId,
          title: originalFilename,
          progress: 100,
          isComplete: true,
        );
        
        // Let the notification stay for a moment then cancel if needed, 
        // or just leave it as "Complete"
        
        emit(UploadSuccess(event.assetId, progressMap: finalMap));
      },
    );
  }
}
