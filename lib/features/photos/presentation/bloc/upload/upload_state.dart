part of 'upload_bloc.dart';

abstract class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

class UploadInitial extends UploadState {}

class UploadInProgress extends UploadState {
  const UploadInProgress({
    required this.tasks,
  });

  final List<UploadTask> tasks;

  double get overallProgress {
    if (tasks.isEmpty) return 0.0;
    return tasks.map((t) => t.progress).reduce((a, b) => a + b) / tasks.length;
  }

  int get completedCount => tasks.where((t) => t.status == UploadStatus.success).length;
  int get totalCount => tasks.length;

  @override
  List<Object?> get props => [tasks];
}

class UploadSuccess extends UploadState {}

class UploadFailure extends UploadState {
  const UploadFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
