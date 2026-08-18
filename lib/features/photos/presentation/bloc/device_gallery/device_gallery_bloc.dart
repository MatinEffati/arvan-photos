import 'dart:async';

import 'package:arvan_photos/features/photos/data/datasources/device_gallery_datasource.dart';
import 'package:arvan_photos/features/photos/data/datasources/backup_local_datasource.dart';
import 'package:arvan_photos/features/photos/domain/entities/local_photo_group.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:arvan_photos/features/photos/domain/usecases/enqueue_backup_usecase.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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
    this._dataSource,
    this._enqueueBackupUseCase,
    this._backupLocalDataSource,
    this._repository,
    this._prefs,
  ) : super(DeviceGalleryInitial()) {
    on<DeviceGalleryRequested>(_onRequested);
    on<DeviceGallerySelectionToggled>(_onSelectionToggled);
    on<DeviceGalleryGroupSelectionToggled>(_onGroupSelectionToggled);
    on<DeviceGallerySelectAllToggled>(_onSelectAllToggled);
    on<DeviceGalleryBackupRequested>(_onBackupRequested);
    on<DeviceGalleryAutoBackupToggled>(_onAutoBackupToggled);
    on<DeviceGallerySettingsRequested>(_onSettingsRequested);

    _statusSubscription = _repository.watchBackupStatus().listen((_) {
      add(const DeviceGallerySettingsRequested());
    });
  }

  final DeviceGalleryDataSource _dataSource;
  final EnqueueBackupUseCase _enqueueBackupUseCase;
  final BackupLocalDataSource _backupLocalDataSource;
  final PhotoCommandRepository _repository;
  final SharedPreferences _prefs;
  StreamSubscription? _statusSubscription;

  static const String _autoBackupKey = 'auto_backup_enabled';

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }

  Future<void> _onRequested(
    DeviceGalleryRequested event,
    Emitter<DeviceGalleryState> emit,
  ) async {
    emit(DeviceGalleryLoadInProgress());
    try {
      final assets = await _dataSource.getLocalAssets();
      final groups = _groupAssets(assets);
      
      final isAutoBackupEnabled = _prefs.getBool(_autoBackupKey) ?? false;
      final syncedIds = await _backupLocalDataSource.getSyncedIds();
      final syncedIdsSet = syncedIds.toSet();

      final notSyncedAssets = assets.where((a) => !syncedIdsSet.contains(a.id)).toList();
      
      emit(DeviceGalleryLoadSuccess(
        groups: groups,
        selectedAssetIds: const {},
        isAutoBackupEnabled: isAutoBackupEnabled,
        notBackedUpCount: notSyncedAssets.length,
        notBackedUpThumbnails: notSyncedAssets.take(4).toList(),
      ));

      // If auto-backup is enabled, automatically enqueue new items
      if (isAutoBackupEnabled) {
        final toEnqueue = notSyncedAssets.map((a) => a.id).toList();
        if (toEnqueue.isNotEmpty) {
          await _enqueueBackupUseCase(toEnqueue);
          // Refresh state to update counts ? Not strictly necessary if background service updates status
        }
      }
    } catch (e) {
      emit(DeviceGalleryLoadFailure(e.toString()));
    }
  }

  List<LocalPhotoGroup> _groupAssets(List<AssetEntity> assets) {
    final Map<String, List<AssetEntity>> grouped = {};
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final asset in assets) {
      final date = asset.createDateTime;
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
      final groupAssets = entry.value;
      final groupDate = groupAssets.first.createDateTime;
      return LocalPhotoGroup(
        title: entry.key,
        date: groupDate,
        assets: groupAssets,
      );
    }).toList();

    groups.sort((a, b) => b.date.compareTo(a.date));
    
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
      
      final allInGroupSelected = groupIds.every((id) => selectedIds.contains(id));
      
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

      await Permission.notification.request();

      emit(DeviceGalleryBackupInProgress(
        groups: currentState.groups,
        selectedAssetIds: currentState.selectedAssetIds,
        isAutoBackupEnabled: currentState.isAutoBackupEnabled,
        notBackedUpCount: currentState.notBackedUpCount,
        notBackedUpThumbnails: currentState.notBackedUpThumbnails,
      ));

      final result = await _enqueueBackupUseCase(currentState.selectedAssetIds.toList());

      result.fold(
        (failure) => emit(DeviceGalleryLoadFailure(failure.toString())),
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

  Future<void> _onAutoBackupToggled(
    DeviceGalleryAutoBackupToggled event,
    Emitter<DeviceGalleryState> emit,
  ) async {
    if (state is DeviceGalleryLoadSuccess) {
      final currentState = state as DeviceGalleryLoadSuccess;
      
      await _prefs.setBool(_autoBackupKey, event.isEnabled);
      
      emit(currentState.copyWith(isAutoBackupEnabled: event.isEnabled));

      if (event.isEnabled) {
        // Enqueue everything that is not synced
        final allAssets = currentState.groups.expand((g) => g.assets).toList();
        final syncedIds = await _backupLocalDataSource.getSyncedIds();
        final syncedIdsSet = syncedIds.toSet();
        
        final toEnqueue = allAssets
            .where((a) => !syncedIdsSet.contains(a.id))
            .map((a) => a.id)
            .toList();

        if (toEnqueue.isNotEmpty) {
          await _enqueueBackupUseCase(toEnqueue);
        }
      }
    }
  }

  Future<void> _onSettingsRequested(
    DeviceGallerySettingsRequested event,
    Emitter<DeviceGalleryState> emit,
  ) async {
    // Just refresh the counts and thumbnails
    if (state is DeviceGalleryLoadSuccess) {
      final currentState = state as DeviceGalleryLoadSuccess;
      final syncedIds = await _backupLocalDataSource.getSyncedIds();
      final syncedIdsSet = syncedIds.toSet();
      
      final allAssets = currentState.groups.expand((g) => g.assets).toList();
      final notSyncedAssets = allAssets.where((a) => !syncedIdsSet.contains(a.id)).toList();

      emit(currentState.copyWith(
        notBackedUpCount: notSyncedAssets.length,
        notBackedUpThumbnails: notSyncedAssets.take(4).toList(),
      ));
    }
  }
}
