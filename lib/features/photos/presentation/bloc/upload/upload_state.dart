part of 'upload_bloc.dart';

abstract class UploadState extends Equatable {
  const UploadState({this.progressMap = const {}});
  
  final Map<String, double> progressMap;

  @override
  List<Object?> get props => [progressMap];
}

class UploadInitial extends UploadState {
  const UploadInitial({super.progressMap});
}

class UploadInProgress extends UploadState {
  const UploadInProgress(this.assetId, {super.progressMap});
  
  final String assetId;
  
  double get progress => progressMap[assetId] ?? 0.0;

  @override
  List<Object?> get props => [assetId, progressMap];
}

class UploadSuccess extends UploadState {
  const UploadSuccess(this.assetId, {super.progressMap});
  final String assetId;

  @override
  List<Object?> get props => [assetId, progressMap];
}

class UploadFailure extends UploadState {
  const UploadFailure(this.assetId, this.message, {super.progressMap});
  final String assetId;
  final String message;

  @override
  List<Object?> get props => [assetId, message, progressMap];
}
