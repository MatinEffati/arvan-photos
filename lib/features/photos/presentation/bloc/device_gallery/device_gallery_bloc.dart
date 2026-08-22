import 'package:arvan_photos/features/photos/data/datasources/photos_local_data_source.dart';
import 'package:arvan_photos/features/photos/domain/entities/device_asset.dart';
import 'package:arvan_photos/features/photos/domain/entities/local_photo_group.dart';
import 'package:arvan_photos/features/photos/domain/usecases/get_local_gallery_usecase.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'device_gallery_event.dart';
part 'device_gallery_state.dart';

@injectable
class DeviceGalleryBloc extends Bloc<DeviceGalleryEvent, DeviceGalleryState> {
  DeviceGalleryBloc(
    this._getLocalGallery,
    this._prefs,
    this._localDataSource,
  ) : super(DeviceGalleryInitial()) {
    on<DeviceGalleryRequested>(_onRequested);
    on<DeviceGallerySelectionToggled>(_onSelectionToggled);
    on<DeviceGalleryGroupSelectionToggled>(_onGroupSelectionToggled);
    on<DeviceGallerySelectAllToggled>(_onSelectAllToggled);
    on<DeviceGallerySelectionCleared>(_onSelectionCleared);
    on<DeviceGalleryGridColumnsChanged>(_onGridColumnsChanged);
    on<DeviceGalleryAutoBackupToggled>(_onAutoBackupToggled);
    on<DeviceGalleryBackupStatusChanged>(_onBackupStatusChanged);

    PhotoManager.addChangeCallback(_onGalleryChanged);
    PhotoManager.startChangeNotify();
  }

  final GetLocalGalleryUseCase _getLocalGallery;
  final SharedPreferences _prefs;
  final PhotosLocalDataSource _localDataSource;

  static const String _gridColumnsKey = 'grid_columns';
  static const String _autoBackupKey = 'auto_backup_enabled';

  void _onGalleryChanged(MethodCall call) {
    add(const DeviceGalleryRequested());
  }

  @override
  Future<void> close() {
    PhotoManager.removeChangeCallback(_onGalleryChanged);
    PhotoManager.stopChangeNotify();
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
      
      final gridColumns = _prefs.getInt(_gridColumnsKey) ?? 3;
      final isAutoBackupEnabled = _prefs.getBool(_autoBackupKey) ?? false;

      final backedUpAssetIds = await _localDataSource.getAllBackedUpAssetIds();
      
      // Calculate not backed up count based on local DB
      final notBackedUpCount = assets.where((a) => !backedUpAssetIds.contains(a.id)).length;
      final notBackedUpThumbnails = assets
          .where((a) => !backedUpAssetIds.contains(a.id))
          .take(5)
          .toList();

      emit(DeviceGalleryLoadSuccess(
        groups: groups,
        selectedAssetIds: const {},
        gridColumns: gridColumns,
        isAutoBackupEnabled: isAutoBackupEnabled,
        notBackedUpCount: notBackedUpCount,
        notBackedUpThumbnails: notBackedUpThumbnails,
        backedUpAssetIds: backedUpAssetIds,
      ));
    } catch (e) {
      emit(DeviceGalleryLoadFailure(e.toString()));
    }
  }

  Future<List<LocalPhotoGroup>> _groupAssetsAsync(List<DeviceAsset> assets) async {
    return _groupAssetsInternal(assets);
  }

  static List<LocalPhotoGroup> _groupAssetsInternal(List<DeviceAsset> assets) {
    final grouped = <String, List<DeviceAsset>>{};
    final fullDateFormatter = DateFormat('E, MMM d, yyyy');
    final weekDayFormatter = DateFormat('EEEE');
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sixDaysAgo = today.subtract(const Duration(days: 6));

    for (final asset in assets) {
      final date = asset.modifiedDateTime;
      final assetDay = DateTime(date.year, date.month, date.day);
      String title;

      if (assetDay == today) {
        title = 'Today';
      } else if (assetDay == yesterday) {
        title = 'Yesterday';
      } else if (assetDay.isAfter(sixDaysAgo)) {
        title = weekDayFormatter.format(date);
      } else {
        title = fullDateFormatter.format(date);
      }

      // Ensure the first letter is always capitalized
      if (title.isNotEmpty) {
        title = title[0].toUpperCase() + title.substring(1);
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

  void _onSelectionCleared(
    DeviceGallerySelectionCleared event,
    Emitter<DeviceGalleryState> emit,
  ) {
    if (state is DeviceGalleryLoadSuccess) {
      final currentState = state as DeviceGalleryLoadSuccess;
      emit(currentState.copyWith(selectedAssetIds: const {}));
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

  Future<void> _onAutoBackupToggled(
    DeviceGalleryAutoBackupToggled event,
    Emitter<DeviceGalleryState> emit,
  ) async {
    if (state is DeviceGalleryLoadSuccess) {
      final currentState = state as DeviceGalleryLoadSuccess;
      await _prefs.setBool(_autoBackupKey, event.enabled);
      
      // Update the state with the new toggle value
      emit(currentState.copyWith(
        isAutoBackupEnabled: event.enabled,
      ));
    }
  }

  void _onBackupStatusChanged(
    DeviceGalleryBackupStatusChanged event,
    Emitter<DeviceGalleryState> emit,
  ) {
    if (state is DeviceGalleryLoadSuccess) {
      final currentState = state as DeviceGalleryLoadSuccess;
      final backedUpIds = Set<String>.from(currentState.backedUpAssetIds);

      if (event.isBackedUp) {
        backedUpIds.add(event.assetId);
      } else {
        backedUpIds.remove(event.assetId);
      }

      emit(currentState.copyWith(backedUpAssetIds: backedUpIds));
    }
  }
}
