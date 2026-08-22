part of 'device_gallery_bloc.dart';

sealed class DeviceGalleryEvent extends Equatable {
  const DeviceGalleryEvent();

  @override
  List<Object?> get props => [];
}

class DeviceGalleryRequested extends DeviceGalleryEvent {
  const DeviceGalleryRequested();
}

class DeviceGallerySelectionToggled extends DeviceGalleryEvent {
  const DeviceGallerySelectionToggled(this.assetId);
  final String assetId;

  @override
  List<Object?> get props => [assetId];
}

class DeviceGalleryGroupSelectionToggled extends DeviceGalleryEvent {
  const DeviceGalleryGroupSelectionToggled(this.dateTitle);
  final String dateTitle;

  @override
  List<Object?> get props => [dateTitle];
}

class DeviceGallerySelectAllToggled extends DeviceGalleryEvent {
  const DeviceGallerySelectAllToggled();
}

class DeviceGalleryGridColumnsChanged extends DeviceGalleryEvent {
  const DeviceGalleryGridColumnsChanged(this.columns);
  final int columns;

  @override
  List<Object?> get props => [columns];
}

class DeviceGalleryAutoBackupToggled extends DeviceGalleryEvent {
  const DeviceGalleryAutoBackupToggled(this.enabled);
  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}
