import 'package:arvan_photos/features/photos/domain/entities/photo_entity.dart';
import 'package:arvan_photos/features/photos/domain/entities/photo_group.dart';
import 'package:arvan_photos/features/photos/domain/entities/sort_option.dart';
import 'package:arvan_photos/features/photos/domain/usecases/delete_multiple_photos_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/get_photos_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

part 'photos_event.dart';
part 'photos_state.dart';

@injectable
class PhotosBloc extends Bloc<PhotosEvent, PhotosState> {
  PhotosBloc(
    this._getPhotosUseCase,
    this._deleteMultiplePhotosUseCase,
  ) : super(PhotosInitial()) {
    on<PhotosRequested>(_onPhotosRequested);
    on<PhotosLoadMoreRequested>(_onPhotosLoadMoreRequested);
    on<PhotosSortChanged>(_onPhotosSortChanged);
    on<PhotoSelectionToggled>(_onPhotoSelectionToggled);
    on<PhotosSelectionCleared>(_onPhotosSelectionCleared);
    on<MultiplePhotosDeleteRequested>(_onMultiplePhotosDeleteRequested);
  }

  final GetPhotosUseCase _getPhotosUseCase;
  final DeleteMultiplePhotosUseCase _deleteMultiplePhotosUseCase;

  Future<void> _onPhotosRequested(
    PhotosRequested event,
    Emitter<PhotosState> emit,
  ) async {
    if (!event.isRefresh) emit(PhotosLoadInProgress());
    
    final result = await _getPhotosUseCase(maxKeys: 50);
    result.fold(
      (failure) => emit(PhotosLoadFailure(failure.message)),
      (paginated) {
        final sortedPhotos = _sortPhotos(paginated.photos, state.sortOption);
        emit(PhotosLoadSuccess(
          photos: sortedPhotos,
          groupedPhotos: _groupPhotos(sortedPhotos),
          sortOption: state.sortOption,
          nextContinuationToken: paginated.nextContinuationToken,
        ));
      },
    );
  }

  Future<void> _onPhotosLoadMoreRequested(
    PhotosLoadMoreRequested event,
    Emitter<PhotosState> emit,
  ) async {
    final currentState = state;
    if (currentState is PhotosLoadSuccess && currentState.hasMore && !currentState.isLoadingMore) {
      emit(currentState.copyWith(isLoadingMore: true));
      
      final result = await _getPhotosUseCase(
        continuationToken: currentState.nextContinuationToken,
        maxKeys: 30,
      );

      result.fold(
        (failure) => emit(currentState.copyWith(isLoadingMore: false)),
        (paginated) {
          final allPhotos = List<PhotoEntity>.from(currentState.photos)..addAll(paginated.photos);
          final sortedPhotos = _sortPhotos(allPhotos, state.sortOption);
          emit(PhotosLoadSuccess(
            photos: sortedPhotos,
            groupedPhotos: _groupPhotos(sortedPhotos),
            sortOption: state.sortOption,
            nextContinuationToken: paginated.nextContinuationToken,
          ));
        },
      );
    }
  }

  void _onPhotosSortChanged(
    PhotosSortChanged event,
    Emitter<PhotosState> emit,
  ) {
    if (state is PhotosLoadSuccess) {
      final currentState = state as PhotosLoadSuccess;
      final sortedPhotos = _sortPhotos(currentState.photos, event.sortOption);
      emit(currentState.copyWith(
        photos: sortedPhotos,
        groupedPhotos: _groupPhotos(sortedPhotos),
        sortOption: event.sortOption,
      ));
    } else {
      emit(state.copyWith(sortOption: event.sortOption));
    }
  }

  void _onPhotoSelectionToggled(
    PhotoSelectionToggled event,
    Emitter<PhotosState> emit,
  ) {
    final currentSelected = Set<String>.from(state.selectedPhotoKeys);
    if (currentSelected.contains(event.photoKey)) {
      currentSelected.remove(event.photoKey);
    } else {
      currentSelected.add(event.photoKey);
    }
    emit(state.copyWith(selectedPhotoKeys: currentSelected));
  }

  void _onPhotosSelectionCleared(
    PhotosSelectionCleared event,
    Emitter<PhotosState> emit,
  ) {
    emit(state.copyWith(selectedPhotoKeys: {}));
  }

  Future<void> _onMultiplePhotosDeleteRequested(
    MultiplePhotosDeleteRequested event,
    Emitter<PhotosState> emit,
  ) async {
    final selectedKeys = state.selectedPhotoKeys.toList();
    if (selectedKeys.isEmpty) return;

    if (state is PhotosLoadSuccess) {
      final currentState = state as PhotosLoadSuccess;
      emit(currentState.copyWith(
        deletingPhotoKeys: Set.from(selectedKeys),
      ));

      final result = await _deleteMultiplePhotosUseCase(selectedKeys);

      result.fold(
        (failure) => emit(PhotosLoadFailure(failure.message)),
        (_) {
          final updatedPhotos = currentState.photos
              .where((p) => !selectedKeys.contains(p.key))
              .toList();
          emit(PhotosLoadSuccess(
            photos: updatedPhotos,
            groupedPhotos: _groupPhotos(updatedPhotos),
            sortOption: currentState.sortOption,
            nextContinuationToken: currentState.nextContinuationToken,
            selectedPhotoKeys: const {},
            deletingPhotoKeys: const {},
          ));
        },
      );
    } else {
      emit(PhotosLoadInProgress());
      final result = await _deleteMultiplePhotosUseCase(selectedKeys);
      result.fold(
        (failure) => emit(PhotosLoadFailure(failure.message)),
        (_) => add(const PhotosRequested()),
      );
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

  List<PhotoGroup> _groupPhotos(List<PhotoEntity> photos) {
    final groups = <String, List<PhotoEntity>>{};
    for (final photo in photos) {
      final dateKey = DateFormat('yyyy-MM-dd').format(photo.lastModified);
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(photo);
    }

    final sortedGroups = groups.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return sortedGroups.map((e) {
      return PhotoGroup(
        date: DateTime.parse(e.key),
        photos: e.value,
      );
    }).toList();
  }
}
