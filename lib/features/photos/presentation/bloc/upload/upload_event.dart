part of 'upload_bloc.dart';

abstract class UploadEvent extends Equatable {
  const UploadEvent();

  @override
  List<Object?> get props => [];
}

class UploadStarted extends UploadEvent {
  const UploadStarted(this.files);
  final List<File> files;

  @override
  List<Object?> get props => [files];
}

class UploadTaskUpdated extends UploadEvent {
  const UploadTaskUpdated(this.task);
  final UploadTask task;

  @override
  List<Object?> get props => [task];
}

class UploadResetRequested extends UploadEvent {}
