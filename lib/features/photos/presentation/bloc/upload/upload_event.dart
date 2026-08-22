part of 'upload_bloc.dart';

abstract class UploadEvent extends Equatable {
  const UploadEvent();

  @override
  List<Object?> get props => [];
}

class UploadPhotoRequested extends UploadEvent {
  const UploadPhotoRequested({
    required this.assetId,
  });

  final String assetId;

  @override
  List<Object?> get props => [assetId];
}
