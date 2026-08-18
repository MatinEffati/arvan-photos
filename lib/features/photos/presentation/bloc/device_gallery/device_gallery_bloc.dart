import 'package:arvan_photos/features/photos/data/datasources/device_gallery_datasource.dart';
import 'package:arvan_photos/features/photos/domain/entities/local_photo_group.dart';
import 'package:arvan_photos/features/photos/domain/usecases/enqueue_backup_usecase.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

part 'device_gallery_event.dart';
part 'device_gallery_state.dart';

@injectable
class DeviceGalleryBloc extends Bloc<DeviceGalleryEvent, DeviceGalleryState> {
  DeviceGalleryBloc(
    this._dataSource,
    this._enqueueBackupUseCase,
  ) : super(DeviceGalleryInitial()) {
    on<DeviceGalleryRequested>(_onRequested);
    on<DeviceGallerySelectionToggled>(_onSelectionToggled);
    on<DeviceGalleryGroupSelectionToggled>(_onGroupSelectionToggled);
    on<DeviceGallerySelectAllToggled>(_onSelectAllToggled);
    on<DeviceGalleryBackupRequested>(_onBackupRequested);
  }

  final DeviceGalleryDataSource _dataSource;
  final EnqueueBackupUseCase _enqueueBackupUseCase;

  Future<void> _onRequested(
    DeviceGalleryRequested event,
    Emitter<DeviceGalleryState> emit,
  ) async {
    emit(DeviceGalleryLoadInProgress());
    try {
      final assets = await _dataSource.getLocalAssets();
      final groups = _groupAssets(assets);
      emit(DeviceGalleryLoadSuccess(groups: groups, selectedAssetIds: const {}));
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
      // Use the creation date of the first asset in the group for sorting purposes
      final groupDate = groupAssets.first.createDateTime;
      return LocalPhotoGroup(
        title: entry.key,
        date: groupDate,
        assets: groupAssets,
      );
    }).toList();

    // Sort groups by date descending (latest first)
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

      // Request notification permission before starting the backup service
      // Note: Even if denied, the foreground service will start, but the user
      // won't see the progress notification. This is handled gracefully.
      await Permission.notification.request();

      emit(DeviceGalleryBackupInProgress(
        groups: currentState.groups,
        selectedAssetIds: currentState.selectedAssetIds,
      ));

      final result = await _enqueueBackupUseCase(currentState.selectedAssetIds.toList());

      result.fold(
        (failure) => emit(DeviceGalleryLoadFailure(failure.toString())),
        (_) => emit(DeviceGalleryBackupSuccess(
          groups: currentState.groups,
          selectedAssetIds: const {},
        )),
      );
    }
  }
}
