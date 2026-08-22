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
    this.gridColumns = 3,
    this.isAutoBackupEnabled = false,
    this.notBackedUpCount = 0,
    this.notBackedUpThumbnails = const [],
    this.backedUpAssetIds = const {},
    this.errorMessage,
  });

  final List<LocalPhotoGroup> groups;
  final Set<String> selectedAssetIds;
  final int gridColumns;
  final bool isAutoBackupEnabled;
  final int notBackedUpCount;
  final List<DeviceAsset> notBackedUpThumbnails;
  final Set<String> backedUpAssetIds;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        groups,
        selectedAssetIds,
        gridColumns,
        isAutoBackupEnabled,
        notBackedUpCount,
        notBackedUpThumbnails,
        backedUpAssetIds,
        errorMessage,
      ];

  DeviceGalleryLoadSuccess copyWith({
    List<LocalPhotoGroup>? groups,
    Set<String>? selectedAssetIds,
    int? gridColumns,
    bool? isAutoBackupEnabled,
    int? notBackedUpCount,
    List<DeviceAsset>? notBackedUpThumbnails,
    Set<String>? backedUpAssetIds,
    String? errorMessage,
  }) {
    return DeviceGalleryLoadSuccess(
      groups: groups ?? this.groups,
      selectedAssetIds: selectedAssetIds ?? this.selectedAssetIds,
      gridColumns: gridColumns ?? this.gridColumns,
      isAutoBackupEnabled: isAutoBackupEnabled ?? this.isAutoBackupEnabled,
      notBackedUpCount: notBackedUpCount ?? this.notBackedUpCount,
      notBackedUpThumbnails:
          notBackedUpThumbnails ?? this.notBackedUpThumbnails,
      backedUpAssetIds: backedUpAssetIds ?? this.backedUpAssetIds,
      errorMessage: errorMessage,
    );
  }
}

class DeviceGalleryLoadFailure extends DeviceGalleryState {
  const DeviceGalleryLoadFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
