import 'package:equatable/equatable.dart';

enum UploadStatus { pending, uploading, success, failure, paused }

class UploadTask extends Equatable {
  const UploadTask({
    required this.id,
    required this.filePath,
    this.progress = 0.0,
    this.status = UploadStatus.pending,
    this.errorMessage,
    this.localAssetId,
  });

  final String id;
  final String filePath;
  final double progress;
  final UploadStatus status;
  final String? errorMessage;
  final String? localAssetId;

  UploadTask copyWith({
    double? progress,
    UploadStatus? status,
    String? errorMessage,
    String? localAssetId,
  }) {
    return UploadTask(
      id: id,
      filePath: filePath,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      localAssetId: localAssetId ?? this.localAssetId,
    );
  }

  @override
  List<Object?> get props => [id, filePath, progress, status, errorMessage, localAssetId];
}
