part of 'upload_bloc.dart';

abstract class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

class UploadInitial extends UploadState {}

class UploadInProgress extends UploadState {
  const UploadInProgress(this.assetId, {this.progress = 0});
  final String assetId;
  final double progress;

  @override
  List<Object?> get props => [assetId, progress];
}

class UploadSuccess extends UploadState {
  const UploadSuccess(this.assetId);
  final String assetId;

  @override
  List<Object?> get props => [assetId];
}

class UploadFailure extends UploadState {
  const UploadFailure(this.assetId, this.message);
  final String assetId;
  final String message;

  @override
  List<Object?> get props => [assetId, message];
}
