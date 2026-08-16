part of 'photos_bloc.dart';

abstract class PhotosEvent extends Equatable {
  const PhotosEvent();

  @override
  List<Object?> get props => [];
}

class PhotosRequested extends PhotosEvent {}

class PhotosSortChanged extends PhotosEvent {
  const PhotosSortChanged(this.sortOption);
  final SortOption sortOption;

  @override
  List<Object?> get props => [sortOption];
}
