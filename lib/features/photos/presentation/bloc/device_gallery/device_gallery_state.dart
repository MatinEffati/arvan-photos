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
    this.deletingAssetIds = const {},
    this.isAutoBackupEnabled = false,
    this.notBackedUpCount = 0,
    this.notBackedUpThumbnails = const [],
    this.cloudCount = 0,
    this.gridColumns = 3,
    this.errorMessage,
  });

  final List<LocalPhotoGroup> groups;
  final Set<String> selectedAssetIds;
  final Set<String> deletingAssetIds;
  final bool isAutoBackupEnabled;
  final int notBackedUpCount;
  final List<AssetEntity> notBackedUpThumbnails;
  final int cloudCount;
  final int gridColumns;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        groups,
        selectedAssetIds,
        deletingAssetIds,
        isAutoBackupEnabled,
        notBackedUpCount,
        notBackedUpThumbnails,
        cloudCount,
        gridColumns,
        errorMessage,
      ];

  DeviceGalleryLoadSuccess copyWith({
    List<LocalPhotoGroup>? groups,
    Set<String>? selectedAssetIds,
    Set<String>? deletingAssetIds,
    bool? isAutoBackupEnabled,
    int? notBackedUpCount,
    List<AssetEntity>? notBackedUpThumbnails,
    int? cloudCount,
    int? gridColumns,
    String? errorMessage,
  }) {
    return DeviceGalleryLoadSuccess(
      groups: groups ?? this.groups,
      selectedAssetIds: selectedAssetIds ?? this.selectedAssetIds,
      deletingAssetIds: deletingAssetIds ?? this.deletingAssetIds,
      isAutoBackupEnabled: isAutoBackupEnabled ?? this.isAutoBackupEnabled,
      notBackedUpCount: notBackedUpCount ?? this.notBackedUpCount,
      notBackedUpThumbnails:
          notBackedUpThumbnails ?? this.notBackedUpThumbnails,
      cloudCount: cloudCount ?? this.cloudCount,
      gridColumns: gridColumns ?? this.gridColumns,
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

class DeviceGalleryBackupInProgress extends DeviceGalleryLoadSuccess {
  const DeviceGalleryBackupInProgress({
    required super.groups,
    required super.selectedAssetIds,
    super.deletingAssetIds,
    required super.isAutoBackupEnabled,
    required super.notBackedUpCount,
    required super.notBackedUpThumbnails,
    super.gridColumns,
  });
}

class DeviceGalleryBackupSuccess extends DeviceGalleryLoadSuccess {
  const DeviceGalleryBackupSuccess({
    required super.groups,
    required super.selectedAssetIds,
    super.deletingAssetIds,
    required super.isAutoBackupEnabled,
    required super.notBackedUpCount,
    required super.notBackedUpThumbnails,
    super.gridColumns,
  });
}

class DeviceGalleryActionInProgress extends DeviceGalleryLoadSuccess {
  const DeviceGalleryActionInProgress({
    required super.groups,
    required super.selectedAssetIds,
    super.deletingAssetIds,
    required super.isAutoBackupEnabled,
    required super.notBackedUpCount,
    required super.notBackedUpThumbnails,
    super.gridColumns,
  });
}
