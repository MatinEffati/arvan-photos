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
  const UploadProgressUpdated({
    required this.progress,
    required this.currentFileIndex,
  });

  final double progress;
  final int currentFileIndex;

  @override
  List<Object?> get props => [progress, currentFileIndex];
}
