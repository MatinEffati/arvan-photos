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

class UploadProgressUpdated extends UploadEvent {
  const UploadProgressUpdated(this.progress);
  final double progress;

  @override
  List<Object?> get props => [progress];
}
