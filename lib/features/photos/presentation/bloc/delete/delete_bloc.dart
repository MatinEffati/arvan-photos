import 'package:arvan_photos/features/photos/data/datasources/photos_local_data_source.dart';
import 'package:arvan_photos/features/photos/domain/usecases/delete_photo_usecase.dart';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'delete_event.dart';
part 'delete_state.dart';

@injectable
class DeleteBloc extends Bloc<DeleteEvent, DeleteState> {
  DeleteBloc(
    this._deletePhoto,
    this._localDataSource,
  ) : super(DeleteInitial()) {
    on<DeletePhotoRequested>(_onDeleteRequested);
  }

  final DeletePhotoUseCase _deletePhoto;
  final PhotosLocalDataSource _localDataSource;

  Future<void> _onDeleteRequested(
    DeletePhotoRequested event,
    Emitter<DeleteState> emit,
  ) async {
    emit(DeleteInProgress(event.assetId));
    
    final remoteKey = await _localDataSource.getRemoteKey(event.assetId);
    if (remoteKey == null) {
      emit(DeleteFailure(event.assetId, 'Photo not found in cloud registry'));
      return;
    }
    
    final result = await _deletePhoto(remoteKey);
    
    await result.fold(
      (failure) async => emit(DeleteFailure(event.assetId, failure.message)),
      (_) async {
        await _localDataSource.removeBackup(event.assetId);
        emit(DeleteSuccess(event.assetId));
      },
    );
  }
}
