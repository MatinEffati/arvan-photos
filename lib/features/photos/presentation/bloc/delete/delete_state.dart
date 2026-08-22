part of 'delete_bloc.dart';

abstract class DeleteState extends Equatable {
  const DeleteState();

  @override
  List<Object?> get props => [];
}

class DeleteInitial extends DeleteState {}

class DeleteInProgress extends DeleteState {
  const DeleteInProgress(this.assetId);
  final String assetId;

  @override
  List<Object?> get props => [assetId];
}

class DeleteSuccess extends DeleteState {
  const DeleteSuccess(this.assetId);
  final String assetId;

  @override
  List<Object?> get props => [assetId];
}

class DeleteFailure extends DeleteState {
  const DeleteFailure(this.assetId, this.message);
  final String assetId;
  final String message;

  @override
  List<Object?> get props => [assetId, message];
}
