part of 'photos_bloc.dart';

abstract class PhotosState extends Equatable {
  const PhotosState({
    this.sortOption = SortOption.dateDescending,
    this.nextContinuationToken,
    this.isLoadingMore = false,
  });

  final SortOption sortOption;
  final String? nextContinuationToken;
  final bool isLoadingMore;

  bool get hasMore => nextContinuationToken != null;

  PhotosState copyWith({
    SortOption? sortOption,
    String? nextContinuationToken,
    bool? isLoadingMore,
  });

  @override
  List<Object?> get props => [sortOption, nextContinuationToken, isLoadingMore];
}

class PhotosInitial extends PhotosState {
  @override
  PhotosInitial copyWith({
    SortOption? sortOption,
    String? nextContinuationToken,
    bool? isLoadingMore,
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
  }) {
    return PhotosLoadInProgress();
  }
}

class PhotosLoadSuccess extends PhotosState {
  const PhotosLoadSuccess({
    required this.photos,
    required SortOption sortOption,
    String? nextContinuationToken,
    bool isLoadingMore = false,
  }) : super(
          sortOption: sortOption,
          nextContinuationToken: nextContinuationToken,
          isLoadingMore: isLoadingMore,
        );

  final List<PhotoEntity> photos;

  @override
  PhotosLoadSuccess copyWith({
    List<PhotoEntity>? photos,
    SortOption? sortOption,
    String? nextContinuationToken,
    bool? isLoadingMore,
    bool clearToken = false,
  }) {
    return PhotosLoadSuccess(
      photos: photos ?? this.photos,
      sortOption: sortOption ?? this.sortOption,
      nextContinuationToken: clearToken ? null : (nextContinuationToken ?? this.nextContinuationToken),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [photos, sortOption, nextContinuationToken, isLoadingMore];
}

class PhotosLoadFailure extends PhotosState {
  const PhotosLoadFailure(this.message);
  final String message;

  @override
  PhotosLoadFailure copyWith({
    SortOption? sortOption,
    String? nextContinuationToken,
    bool? isLoadingMore,
  }) {
    return PhotosLoadFailure(message);
  }

  @override
  List<Object?> get props => [message, sortOption, nextContinuationToken, isLoadingMore];
}
