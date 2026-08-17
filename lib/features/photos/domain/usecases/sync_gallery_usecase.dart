import 'package:flutter/foundation.dart';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/data/datasources/device_gallery_datasource.dart';
import 'package:arvan_photos/features/photos/data/datasources/sync_local_datasource.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class SyncGalleryUseCase {
  SyncGalleryUseCase(
    this._deviceDataSource,
    this._syncLocalDataSource,
    this._commandRepository,
  );

  final DeviceGalleryDataSource _deviceDataSource;
  final SyncLocalDataSource _syncLocalDataSource;
  final PhotoCommandRepository _commandRepository;

  Future<Either<Failure, Unit>> call({
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('SYNC_LOG: Starting sync process...');
      final assets = await _deviceDataSource.getLocalAssets();
      debugPrint('SYNC_LOG: Local assets count: ${assets.length}');
      
      if (assets.isEmpty) return const Right(unit);

      final syncedIds = await _syncLocalDataSource.getAllSyncedIds();
      debugPrint('SYNC_LOG: Already synced IDs in DB: ${syncedIds.length}');
      
      final toSync = assets.where((a) => !syncedIds.contains(a.id)).toList();
      debugPrint('SYNC_LOG: Assets to sync: ${toSync.length}');

      if (toSync.isEmpty) return const Right(unit);

      for (var i = 0; i < toSync.length; i++) {
        final asset = toSync[i];
        print('SYNC_LOG: Syncing asset ${i + 1}/${toSync.length}: ${asset.id}');
        
        final file = await asset.file;
        if (file == null) {
          print('SYNC_LOG: File is null for asset ${asset.id}, skipping...');
          continue;
        }
        
        final result = await _commandRepository.uploadPhoto(file);
        
        await result.fold(
          (failure) async {
            print('SYNC_LOG: Failed to upload ${asset.id}: ${failure.message}');
            await _syncLocalDataSource.markFailed(asset.id);
          },
          (_) async {
            print('SYNC_LOG: Successfully uploaded ${asset.id}');
            await _syncLocalDataSource.markSynced(asset.id, 'synced_${asset.id}');
          },
        );
        
        if (onProgress != null) {
          onProgress(i + 1, toSync.length);
        }
      }

      print('SYNC_LOG: Sync process finished');
      return const Right(unit);
    } catch (e) {
      print('SYNC_LOG: Error during sync: $e');
      return Left(UnknownFailure(e.toString()));
    }
  }
}
