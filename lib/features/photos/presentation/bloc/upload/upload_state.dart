part of 'upload_bloc.dart';

abstract class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

class UploadInitial extends UploadState {}

class UploadInProgress extends UploadState {
  const UploadInProgress(
    this.progress, {
    required this.totalFiles,
    required this.currentFileIndex,
  });

  final double progress;
  final int totalFiles;
  final int currentFileIndex;

  @override
  List<Object?> get props => [progress, totalFiles, currentFileIndex];
}

class UploadSuccess extends UploadState {}

class UploadFailure extends UploadState {
  const UploadFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
