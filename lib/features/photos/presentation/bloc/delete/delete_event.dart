part of 'delete_bloc.dart';

abstract class DeleteEvent extends Equatable {
  const DeleteEvent();

  @override
  List<Object?> get props => [];
}

class DeletePhotoRequested extends DeleteEvent {
  const DeletePhotoRequested(this.assetId);
  final String assetId;

  @override
  List<Object?> get props => [assetId];
}
