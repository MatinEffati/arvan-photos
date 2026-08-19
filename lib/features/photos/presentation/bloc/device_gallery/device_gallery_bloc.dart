import 'dart:async';

import 'package:arvan_photos/features/photos/domain/entities/device_asset.dart';
import 'package:arvan_photos/features/photos/domain/entities/local_photo_group.dart';
import 'package:arvan_photos/features/photos/domain/usecases/delete_backup_from_cloud_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/enqueue_backup_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/get_asset_path_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/get_backup_status_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/get_cloud_count_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/get_local_gallery_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/get_synced_ids_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/watch_backup_status_usecase.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'device_gallery_event.dart';
part 'device_gallery_state.dart';

@injectable
class DeviceGalleryBloc extends Bloc<DeviceGalleryEvent, DeviceGalleryState> {
  DeviceGalleryBloc(
    this._getLocalGallery,
    this._getBackupStatuses,
    this._getSyncedIds,
    this._getAssetPath,
    this._getCloudCount,
    this._enqueueBackup,
    this._deleteBackup,
    this._watchBackupStatus,
    this._prefs,
  ) : super(DeviceGalleryInitial()) {
    on<DeviceGalleryRequested>(_onRequested);
    on<DeviceGallerySelectionToggled>(_onSelectionToggled);
    on<DeviceGalleryGroupSelectionToggled>(_onGroupSelectionToggled);
    on<DeviceGallerySelectAllToggled>(_onSelectAllToggled);
    on<DeviceGalleryBackupRequested>(_onBackupRequested);
    on<DeviceGalleryDeleteFromCloudRequested>(_onDeleteFromCloudRequested);
    on<DeviceGalleryAutoBackupToggled>(_onAutoBackupToggled);
    on<DeviceGallerySettingsRequested>(_onSettingsRequested);
    on<DeviceGalleryGridColumnsChanged>(_onGridColumnsChanged);

    _statusSubscription = _watchBackupStatus().listen((event) {
      final status = event['status'] as String?;
      if (status == 'synced' || status == 'manually_removed') {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 2), () {
          add(const DeviceGallerySettingsRequested());
        });
      }
    });

    PhotoManager.addChangeCallback(_onGalleryChanged);
    PhotoManager.startChangeNotify();
  }

  final GetLocalGalleryUseCase _getLocalGallery;
  final GetBackupStatusUseCase _getBackupStatuses;
  final GetSyncedIdsUseCase _getSyncedIds;
  final GetAssetPathUseCase _getAssetPath;
  final GetCloudCountUseCase _getCloudCount;
  final EnqueueBackupUseCase _enqueueBackup;
  final DeleteBackupFromCloudUseCase _deleteBackup;
  final WatchBackupStatusUseCase _watchBackupStatus;
  final SharedPreferences _prefs;
  StreamSubscription? _statusSubscription;
  Timer? _debounceTimer;

  static const String _autoBackupKey = 'auto_backup_enabled';
  static const String _gridColumnsKey = 'grid_columns';

  void _onGalleryChanged(MethodCall call) {
    add(const DeviceGalleryRequested());
  }

  @override
  Future<void> close() {
    PhotoManager.removeChangeCallback(_onGalleryChanged);
    PhotoManager.stopChangeNotify();
    _statusSubscription?.cancel();
    _debounceTimer?.cancel();
    return super.close();
  }

  Future<void> _onRequested(
    DeviceGalleryRequested event,
    Emitter<DeviceGalleryState> emit,
  ) async {
    final isSilent = state is DeviceGalleryLoadSuccess;
    if (!isSilent) emit(DeviceGalleryLoadInProgress());
    
    try {
      final assets = await _getLocalGallery();
      final groups = await _groupAssetsAsync(assets);
      
      final isAutoBackupEnabled = _prefs.getBool(_autoBackupKey) ?? false;
      final gridColumns = _prefs.getInt(_gridColumnsKey) ?? 3;
      final syncedIds = await _getSyncedIds();
      final syncedIdsSet = syncedIds.toSet();
      
      final allStatuses = await _getBackupStatuses();
      final inQueueSet = allStatuses.map((e) => e.assetId).toSet();

      final notSyncedAssets = assets.where((a) => !syncedIdsSet.contains(a.id)).toList();
      
      final cloudCountResult = await _getCloudCount();
      final cloudCount = cloudCountResult.fold((_) => 0, (count) => count);

      emit(DeviceGalleryLoadSuccess(
        groups: groups,
        selectedAssetIds: const {},
        isAutoBackupEnabled: isAutoBackupEnabled,
        notBackedUpCount: notSyncedAssets.length,
        notBackedUpThumbnails: notSyncedAssets.take(4).toList(),
        cloudCount: cloudCount,
        gridColumns: gridColumns,
      ));

      if (isAutoBackupEnabled) {
        final toEnqueueAssets = assets
            .where((a) =>
                !syncedIdsSet.contains(a.id) && !inQueueSet.contains(a.id))
            .toList();

        if (toEnqueueAssets.isNotEmpty) {
          final toEnqueue = <Map<String, String>>[];
          for (final asset in toEnqueueAssets) {
            final path = await _getAssetPath(asset.id);
            if (path != null) {
              toEnqueue.add({'id': asset.id, 'path': path});
            }
          }
          if (toEnqueue.isNotEmpty) {
            await _enqueueBackup(toEnqueue);
          }
        }
      }
    } catch (e) {
      emit(DeviceGalleryLoadFailure(e.toString()));
    }
  }

  Future<List<LocalPhotoGroup>> _groupAssetsAsync(List<DeviceAsset> assets) async {
    return _groupAssetsInternal(assets);
  }

  static List<LocalPhotoGroup> _groupAssetsInternal(List<DeviceAsset> assets) {
    final grouped = <String, List<DeviceAsset>>{};
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final asset in assets) {
      final date = asset.modifiedDateTime;
      final assetDay = DateTime(date.year, date.month, date.day);
      String title;

      if (assetDay == today) {
        title = 'Today';
      } else if (assetDay == yesterday) {
        title = 'Yesterday';
      } else {
        title = formatter.format(date);
      }

      grouped.putIfAbsent(title, () => []).add(asset);
    }

    final List<LocalPhotoGroup> groups = grouped.entries.map((entry) {
      final groupAssets = entry.value
      ..sort((a, b) => b.modifiedDateTime.compareTo(a.modifiedDateTime));
      
      final groupDate = groupAssets.first.modifiedDateTime;
      return LocalPhotoGroup(
        title: entry.key,
        date: groupDate,
        assets: groupAssets,
      );
    }).toList()

    ..sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  void _onSelectionToggled(
    DeviceGallerySelectionToggled event,
    Emitter<DeviceGalleryState> emit,
  ) {
    if (state is DeviceGalleryLoadSuccess) {
      final currentState = state as DeviceGalleryLoadSuccess;
      final selectedIds = Set<String>.from(currentState.selectedAssetIds);

      if (selectedIds.contains(event.assetId)) {
        selectedIds.remove(event.assetId);
      } else {
        selectedIds.add(event.assetId);
      }

      emit(currentState.copyWith(selectedAssetIds: selectedIds));
    }
  }

  void _onGroupSelectionToggled(
    DeviceGalleryGroupSelectionToggled event,
    Emitter<DeviceGalleryState> emit,
  ) {
    if (state is DeviceGalleryLoadSuccess) {
      final currentState = state as DeviceGalleryLoadSuccess;
      final group = currentState.groups.firstWhere((g) => g.title == event.dateTitle);
      final groupIds = group.assets.map((a) => a.id).toSet();
      
      final selectedIds = Set<String>.from(currentState.selectedAssetIds);
      
      final allInGroupSelected = groupIds.every(selectedIds.contains);
      
      if (allInGroupSelected) {
        selectedIds.removeAll(groupIds);
      } else {
        selectedIds.addAll(groupIds);
      }

      emit(currentState.copyWith(selectedAssetIds: selectedIds));
    }
  }

  void _onSelectAllToggled(
    DeviceGallerySelectAllToggled event,
    Emitter<DeviceGalleryState> emit,
  ) {
    if (state is DeviceGalleryLoadSuccess) {
      final currentState = state as DeviceGalleryLoadSuccess;
      final allIds = currentState.groups.expand((g) => g.assets).map((a) => a.id).toSet();
      
      if (currentState.selectedAssetIds.length == allIds.length) {
        emit(currentState.copyWith(selectedAssetIds: const {}));
      } else {
        emit(currentState.copyWith(selectedAssetIds: allIds));
      }
    }
  }

  Future<void> _onBackupRequested(
    DeviceGalleryBackupRequested event,
    Emitter<DeviceGalleryState> emit,
  ) async {
    if (state is DeviceGalleryLoadSuccess) {
      final currentState = state as DeviceGalleryLoadSuccess;
      if (currentState.selectedAssetIds.isEmpty) return;

      final permission = await Permission.notification.status;
      if (!permission.isGranted) {
        await Permission.notification.request();
      }

      emit(DeviceGalleryBackupInProgress(
        groups: currentState.groups,
        selectedAssetIds: currentState.selectedAssetIds,
        isAutoBackupEnabled: currentState.isAutoBackupEnabled,
        notBackedUpCount: currentState.notBackedUpCount,
        notBackedUpThumbnails: currentState.notBackedUpThumbnails,
      ));

      final assets = currentState.groups
          .expand((g) => g.assets)
          .where((a) => currentState.selectedAssetIds.contains(a.id))
          .toList();

      final toEnqueue = <Map<String, String>>[];
      for (final asset in assets) {
        final path = await _getAssetPath(asset.id);
        if (path != null) {
          toEnqueue.add({'id': asset.id, 'path': path});
        }
      }

      final result = await _enqueueBackup(toEnqueue);

      result.fold(
        (failure) => emit(DeviceGalleryLoadFailure(failure.message)),
        (_) => emit(DeviceGalleryBackupSuccess(
          groups: currentState.groups,
          selectedAssetIds: const {},
          isAutoBackupEnabled: currentState.isAutoBackupEnabled,
          notBackedUpCount: currentState.notBackedUpCount,
          notBackedUpThumbnails: currentState.notBackedUpThumbnails,
        )),
      );
    }
  }

  Future<void> _onDeleteFromCloudRequested(
    DeviceGalleryDeleteFromCloudRequested event,
    Emitter<DeviceGalleryState> emit,
  ) async {
    if (state is DeviceGalleryLoadSuccess) {
      final currentState = state as DeviceGalleryLoadSuccess;
      
      emit(DeviceGalleryActionInProgress(
        groups: currentState.groups,
        selectedAssetIds: currentState.selectedAssetIds,
        deletingAssetIds: Set.from(event.assetIds),
        isAutoBackupEnabled: currentState.isAutoBackupEnabled,
        notBackedUpCount: currentState.notBackedUpCount,
        notBackedUpThumbnails: currentState.notBackedUpThumbnails,
      ));

      final result = await _deleteBackup(event.assetIds);
      
      result.fold(
        (failure) {
          emit(currentState.copyWith(
            deletingAssetIds: {},
            errorMessage: failure.message,
          ));
        },
        (_) {
          add(const DeviceGalleryRequested());
        },
      );
    }
  }

  Future<void> _onAutoBackupToggled(
    DeviceGalleryAutoBackupToggled event,
    Emitter<DeviceGalleryState> emit,
  ) async {
    if (state is DeviceGalleryLoadSuccess) {
      final currentState = state as DeviceGalleryLoadSuccess;
      
      await _prefs.setBool(_autoBackupKey, event.isEnabled);
      
      emit(currentState.copyWith(isAutoBackupEnabled: event.isEnabled));

      if (event.isEnabled) {
        final allAssets = currentState.groups.expand((g) => g.assets).toList();
        final syncedIds = await _getSyncedIds();
        final syncedIdsSet = syncedIds.toSet();

        final toEnqueueAssets =
            allAssets.where((a) => !syncedIdsSet.contains(a.id)).toList();

        if (toEnqueueAssets.isNotEmpty) {
          final toEnqueue = <Map<String, String>>[];
          for (final asset in toEnqueueAssets) {
            final path = await _getAssetPath(asset.id);
            if (path != null) {
              toEnqueue.add({'id': asset.id, 'path': path});
            }
          }
          if (toEnqueue.isNotEmpty) {
            await _enqueueBackup(toEnqueue);
          }
        }
      }
    }
  }

  Future<void> _onSettingsRequested(
    DeviceGallerySettingsRequested event,
    Emitter<DeviceGalleryState> emit,
  ) async {
    if (state is DeviceGalleryLoadSuccess) {
      final currentState = state as DeviceGalleryLoadSuccess;
      final syncedIds = await _getSyncedIds();
      final syncedIdsSet = syncedIds.toSet();
      
      final allAssets = currentState.groups.expand((g) => g.assets).toList();
      final notSyncedAssets = allAssets.where((a) => !syncedIdsSet.contains(a.id)).toList();

      final cloudCountResult = await _getCloudCount();
      final cloudCount = cloudCountResult.fold((_) => 0, (count) => count);

      emit(currentState.copyWith(
        notBackedUpCount: notSyncedAssets.length,
        notBackedUpThumbnails: notSyncedAssets.take(4).toList(),
        cloudCount: cloudCount,
      ));
    }
  }

  Future<void> _onGridColumnsChanged(
    DeviceGalleryGridColumnsChanged event,
    Emitter<DeviceGalleryState> emit,
  ) async {
    if (state is DeviceGalleryLoadSuccess) {
      final currentState = state as DeviceGalleryLoadSuccess;
      await _prefs.setInt(_gridColumnsKey, event.columns);
      emit(currentState.copyWith(gridColumns: event.columns));
    }
  }
}
