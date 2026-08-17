part of 'photos_bloc.dart';

abstract class PhotosState extends Equatable {
  const PhotosState({
    this.sortOption = SortOption.dateDescending,
    this.nextContinuationToken,
    this.isLoadingMore = false,
    this.selectedPhotoKeys = const {},
  });

  final SortOption sortOption;
  final String? nextContinuationToken;
  final bool isLoadingMore;
  final Set<String> selectedPhotoKeys;

  bool get hasMore => nextContinuationToken != null;
  bool get isSelectionMode => selectedPhotoKeys.isNotEmpty;

  PhotosState copyWith({
    SortOption? sortOption,
    String? nextContinuationToken,
    bool? isLoadingMore,
    Set<String>? selectedPhotoKeys,
  });

  @override
  List<Object?> get props => [sortOption, nextContinuationToken, isLoadingMore, selectedPhotoKeys];
}

class PhotosInitial extends PhotosState {
  @override
  PhotosInitial copyWith({
    SortOption? sortOption,
    String? nextContinuationToken,
    bool? isLoadingMore,
    Set<String>? selectedPhotoKeys,
  }) {
    return PhotosInitial();
  }
}

class PhotosLoadInProgress extends PhotosState {
  @override
  PhotosLoadInProgress copyWith({
    SortOption? sortOption,
    String? nextContinuationToken,
    bool? isLoadingMore,
    Set<String>? selectedPhotoKeys,
  }) {
    return PhotosLoadInProgress();
  }
}

class PhotosLoadSuccess extends PhotosState {
  const PhotosLoadSuccess({
    required this.photos,
    required this.groupedPhotos,
    required super.sortOption,
    super.nextContinuationToken,
    super.isLoadingMore = false,
    super.selectedPhotoKeys = const {},
  });

  final List<PhotoEntity> photos;
  final List<PhotoGroup> groupedPhotos;

  @override
  PhotosLoadSuccess copyWith({
    List<PhotoEntity>? photos,
    List<PhotoGroup>? groupedPhotos,
    SortOption? sortOption,
    String? nextContinuationToken,
    bool? isLoadingMore,
    Set<String>? selectedPhotoKeys,
    bool clearToken = false,
  }) {
    return PhotosLoadSuccess(
      photos: photos ?? this.photos,
      groupedPhotos: groupedPhotos ?? this.groupedPhotos,
      sortOption: sortOption ?? this.sortOption,
      nextContinuationToken: clearToken ? null : (nextContinuationToken ?? this.nextContinuationToken),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedPhotoKeys: selectedPhotoKeys ?? this.selectedPhotoKeys,
    );
  }

  @override
  List<Object?> get props => [photos, groupedPhotos, sortOption, nextContinuationToken, isLoadingMore, selectedPhotoKeys];
}

class PhotosLoadFailure extends PhotosState {
  const PhotosLoadFailure(this.message);
  final String message;

  @override
  PhotosLoadFailure copyWith({
    SortOption? sortOption,
    String? nextContinuationToken,
    bool? isLoadingMore,
    Set<String>? selectedPhotoKeys,
  }) {
    return PhotosLoadFailure(message);
  }

  @override
  List<Object?> get props => [message, sortOption, nextContinuationToken, isLoadingMore, selectedPhotoKeys];
}
