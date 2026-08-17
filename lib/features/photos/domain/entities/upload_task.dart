import 'dart:io';
import 'package:equatable/equatable.dart';

enum UploadStatus { pending, uploading, success, failure }

class UploadTask extends Equatable {
  const UploadTask({
    required this.id,
    required this.file,
    this.progress = 0.0,
    this.status = UploadStatus.pending,
    this.errorMessage,
  });

  final String id;
  final File file;
  final double progress;
  final UploadStatus status;
  final String? errorMessage;

  UploadTask copyWith({
    double? progress,
    UploadStatus? status,
    String? errorMessage,
  }) {
    return UploadTask(
      id: id,
      file: file,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [id, file, progress, status, errorMessage];
}
