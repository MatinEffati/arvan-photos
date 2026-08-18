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
    this.isAutoBackupEnabled = false,
    this.notBackedUpCount = 0,
    this.notBackedUpThumbnails = const [],
  });

  final List<LocalPhotoGroup> groups;
  final Set<String> selectedAssetIds;
  final bool isAutoBackupEnabled;
  final int notBackedUpCount;
  final List<AssetEntity> notBackedUpThumbnails;

  @override
  List<Object?> get props => [
        groups,
        selectedAssetIds,
        isAutoBackupEnabled,
        notBackedUpCount,
        notBackedUpThumbnails,
      ];

  DeviceGalleryLoadSuccess copyWith({
    List<LocalPhotoGroup>? groups,
    Set<String>? selectedAssetIds,
    bool? isAutoBackupEnabled,
    int? notBackedUpCount,
    List<AssetEntity>? notBackedUpThumbnails,
  }) {
    return DeviceGalleryLoadSuccess(
      groups: groups ?? this.groups,
      selectedAssetIds: selectedAssetIds ?? this.selectedAssetIds,
      isAutoBackupEnabled: isAutoBackupEnabled ?? this.isAutoBackupEnabled,
      notBackedUpCount: notBackedUpCount ?? this.notBackedUpCount,
      notBackedUpThumbnails:
          notBackedUpThumbnails ?? this.notBackedUpThumbnails,
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
    required super.isAutoBackupEnabled,
    required super.notBackedUpCount,
    required super.notBackedUpThumbnails,
  });
}

class DeviceGalleryBackupSuccess extends DeviceGalleryLoadSuccess {
  const DeviceGalleryBackupSuccess({
    required super.groups,
    required super.selectedAssetIds,
    required super.isAutoBackupEnabled,
    required super.notBackedUpCount,
    required super.notBackedUpThumbnails,
  });
}
