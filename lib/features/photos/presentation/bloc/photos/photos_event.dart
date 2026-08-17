part of 'photos_bloc.dart';

abstract class PhotosEvent extends Equatable {
  const PhotosEvent();

  @override
  List<Object?> get props => [];
}

class PhotosRequested extends PhotosEvent {
  const PhotosRequested({this.isRefresh = false});
  final bool isRefresh;

  @override
  List<Object?> get props => [isRefresh];
}

class PhotosLoadMoreRequested extends PhotosEvent {}

class PhotosSortChanged extends PhotosEvent {
  const PhotosSortChanged(this.sortOption);
  final SortOption sortOption;

  @override
  List<Object?> get props => [sortOption];
}

class PhotoSelectionToggled extends PhotosEvent {
  const PhotoSelectionToggled(this.photoKey);
  final String photoKey;

  @override
  List<Object?> get props => [photoKey];
}

class PhotosSelectionCleared extends PhotosEvent {}

class MultiplePhotosDeleteRequested extends PhotosEvent {}
