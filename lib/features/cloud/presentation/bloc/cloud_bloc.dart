import 'package:arvan_photos/features/cloud/domain/usecases/get_cloud_photos.dart';
import 'package:arvan_photos/features/cloud/presentation/bloc/cloud_event.dart';
import 'package:arvan_photos/features/cloud/presentation/bloc/cloud_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class CloudBloc extends Bloc<CloudEvent, CloudState> {
  CloudBloc(this._getCloudPhotos) : super(CloudInitial()) {
    on<CloudPhotosRequested>(_onPhotosRequested);
    on<CloudLoadMoreRequested>(_onLoadMoreRequested);
  }

  final GetCloudPhotos _getCloudPhotos;

  Future<void> _onPhotosRequested(
    CloudPhotosRequested event,
    Emitter<CloudState> emit,
  ) async {
    if (event.isRefresh) {
      emit(CloudLoadInProgress());
    } else {
      // If already loaded and not refresh, don't show full loading
      if (state is CloudLoadSuccess) return;
      emit(CloudLoadInProgress());
    }
    
    try {
      final paginatedPhotos = await _getCloudPhotos();
      emit(CloudLoadSuccess(
        photos: paginatedPhotos.photos,
        hasReachedMax: paginatedPhotos.nextContinuationToken == null,
        nextContinuationToken: paginatedPhotos.nextContinuationToken,
      ));
    } catch (e) {
      emit(CloudLoadFailure(e.toString()));
    }
  }

  Future<void> _onLoadMoreRequested(
    CloudLoadMoreRequested event,
    Emitter<CloudState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CloudLoadSuccess || currentState.hasReachedMax) return;

    try {
      final paginatedPhotos = await _getCloudPhotos(
        continuationToken: currentState.nextContinuationToken,
      );
      
      emit(CloudLoadSuccess(
        photos: List.of(currentState.photos)..addAll(paginatedPhotos.photos),
        hasReachedMax: paginatedPhotos.nextContinuationToken == null,
        nextContinuationToken: paginatedPhotos.nextContinuationToken,
      ));
    } catch (e) {
      // Handle error without losing current photos if needed, 
      // but for simplicity we'll just keep current state
    }
  }
}
