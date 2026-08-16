part of 'upload_bloc.dart';

abstract class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

class UploadInitial extends UploadState {}

class UploadInProgress extends UploadState {
  const UploadInProgress(this.progress);
  final double progress;

  @override
  List<Object?> get props => [progress];
}

class UploadSuccess extends UploadState {}

class UploadFailure extends UploadState {
  const UploadFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
