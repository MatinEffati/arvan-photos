import 'package:arvan_photos/features/photos/domain/entities/photo_entity.dart';
import 'package:arvan_photos/features/photos/domain/entities/sort_option.dart';
import 'package:arvan_photos/features/photos/domain/usecases/get_photos_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'photos_event.dart';
part 'photos_state.dart';

@injectable
class PhotosBloc extends Bloc<PhotosEvent, PhotosState> {
  PhotosBloc(this._getPhotosUseCase) : super(PhotosInitial()) {
    on<PhotosRequested>(_onPhotosRequested);
    on<PhotosSortChanged>(_onPhotosSortChanged);
  }

  final GetPhotosUseCase _getPhotosUseCase;

  Future<void> _onPhotosRequested(
    PhotosRequested event,
    Emitter<PhotosState> emit,
  ) async {
    emit(PhotosLoadInProgress());
    final result = await _getPhotosUseCase();
    result.fold(
      (failure) => emit(PhotosLoadFailure(failure.message)),
      (photos) {
        final sortedPhotos = _sortPhotos(photos, state.sortOption);
        emit(PhotosLoadSuccess(sortedPhotos, state.sortOption));
      },
    );
  }

  void _onPhotosSortChanged(
    PhotosSortChanged event,
    Emitter<PhotosState> emit,
  ) {
    if (state is PhotosLoadSuccess) {
      final currentState = state as PhotosLoadSuccess;
      final sortedPhotos = _sortPhotos(currentState.photos, event.sortOption);
      emit(PhotosLoadSuccess(sortedPhotos, event.sortOption));
    } else {
      emit(state.copyWith(sortOption: event.sortOption));
    }
  }

  List<PhotoEntity> _sortPhotos(List<PhotoEntity> photos, SortOption option) {
    final sortedList = List<PhotoEntity>.from(photos);
    switch (option) {
      case SortOption.dateDescending:
        sortedList.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      case SortOption.dateAscending:
        sortedList.sort((a, b) => a.lastModified.compareTo(b.lastModified));
      case SortOption.nameAscending:
        sortedList.sort((a, b) => a.name.compareTo(b.name));
      case SortOption.nameDescending:
        sortedList.sort((a, b) => b.name.compareTo(a.name));
      case SortOption.sizeDescending:
        sortedList.sort((a, b) => b.size.compareTo(a.size));
    }
    return sortedList;
  }
}
