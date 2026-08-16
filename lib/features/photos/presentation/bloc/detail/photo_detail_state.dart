part of 'photo_detail_cubit.dart';

abstract class PhotoDetailState extends Equatable {
  const PhotoDetailState();

  @override
  List<Object?> get props => [];
}

class PhotoDetailInitial extends PhotoDetailState {}

class PhotoDetailActionInProgress extends PhotoDetailState {}

class PhotoDetailDeleteSuccess extends PhotoDetailState {}

class PhotoDetailEditSuccess extends PhotoDetailState {}

class PhotoDetailActionFailure extends PhotoDetailState {
  const PhotoDetailActionFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
