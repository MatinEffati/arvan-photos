part of 'upload_bloc.dart';

abstract class UploadEvent extends Equatable {
  const UploadEvent();

  @override
  List<Object?> get props => [];
}

class UploadStarted extends UploadEvent {
  const UploadStarted(this.file);
  final File file;

  @override
  List<Object?> get props => [file];
}
