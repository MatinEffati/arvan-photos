part of 'device_gallery_bloc.dart';

sealed class DeviceGalleryState extends Equatable {
  const DeviceGalleryState();

  @override
  List<Object?> get props => [];
}

class DeviceGalleryInitial extends DeviceGalleryState {}

class DeviceGalleryLoadInProgress extends DeviceGalleryState {}

class DeviceGalleryLoadSuccess extends DeviceGalleryState {
  const DeviceGalleryLoadSuccess({
    required this.groups,
    required this.selectedAssetIds,
  });

  final List<LocalPhotoGroup> groups;
  final Set<String> selectedAssetIds;

  @override
  List<Object?> get props => [groups, selectedAssetIds];

  DeviceGalleryLoadSuccess copyWith({
    List<LocalPhotoGroup>? groups,
    Set<String>? selectedAssetIds,
  }) {
    return DeviceGalleryLoadSuccess(
      groups: groups ?? this.groups,
      selectedAssetIds: selectedAssetIds ?? this.selectedAssetIds,
    );
  }
}

class DeviceGalleryLoadFailure extends DeviceGalleryState {
  const DeviceGalleryLoadFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class DeviceGalleryBackupInProgress extends DeviceGalleryLoadSuccess {
  const DeviceGalleryBackupInProgress({
    required super.groups,
    required super.selectedAssetIds,
  });
}

class DeviceGalleryBackupSuccess extends DeviceGalleryLoadSuccess {
  const DeviceGalleryBackupSuccess({
    required super.groups,
    required super.selectedAssetIds,
  }) : super();
}
