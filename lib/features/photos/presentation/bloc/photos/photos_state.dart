part of 'photos_bloc.dart';

abstract class PhotosState extends Equatable {
  const PhotosState({this.sortOption = SortOption.dateDescending});
  final SortOption sortOption;

  PhotosState copyWith({SortOption? sortOption});

  @override
  List<Object?> get props => [sortOption];
}

class PhotosInitial extends PhotosState {
  @override
  PhotosInitial copyWith({SortOption? sortOption}) {
    return PhotosInitial();
  }
}

class PhotosLoadInProgress extends PhotosState {
  @override
  PhotosLoadInProgress copyWith({SortOption? sortOption}) {
    return PhotosLoadInProgress();
  }
}

class PhotosLoadSuccess extends PhotosState {
  const PhotosLoadSuccess(this.photos, SortOption sortOption)
      : super(sortOption: sortOption);
  final List<PhotoEntity> photos;

  @override
  PhotosLoadSuccess copyWith({SortOption? sortOption}) {
    return PhotosLoadSuccess(photos, sortOption ?? this.sortOption);
  }

  @override
  List<Object?> get props => [photos, sortOption];
}

class PhotosLoadFailure extends PhotosState {
  const PhotosLoadFailure(this.message);
  final String message;

  @override
  PhotosLoadFailure copyWith({SortOption? sortOption}) {
    return PhotosLoadFailure(message);
  }

  @override
  List<Object?> get props => [message, sortOption];
}
