import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/data/datasources/device_gallery_datasource.dart';
import 'package:arvan_photos/features/photos/data/datasources/sync_local_datasource.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'package:arvan_photos/features/photos/data/datasources/upload_local_datasource.dart';
import 'package:arvan_photos/features/photos/domain/entities/upload_task.dart';
import 'package:uuid/uuid.dart';

@injectable
class SyncGalleryUseCase {
  SyncGalleryUseCase(
    this._deviceDataSource,
    this._syncLocalDataSource,
    this._uploadLocalDataSource,
  );

  final DeviceGalleryDataSource _deviceDataSource;
  final SyncLocalDataSource _syncLocalDataSource;
  final UploadLocalDataSource _uploadLocalDataSource;
  final _uuid = const Uuid();

  Future<Either<Failure, Unit>> call({
    void Function(int current, int total, double individualProgress)? onProgress,
  }) async {
    try {
      final assets = await _deviceDataSource.getLocalAssets();
      if (assets.isEmpty) return const Right(unit);

      final registeredIds = await _syncLocalDataSource.getRegisteredIds();
      final toSync = assets.where((a) => !registeredIds.contains(a.id)).toList();

      if (toSync.isEmpty) return const Right(unit);

      for (var i = 0; i < toSync.length; i++) {
        final asset = toSync[i];
        final file = await asset.file;
        
        if (file != null) {
          // Instead of uploading directly, add to the background upload queue
          final task = UploadTask(
            id: _uuid.v4(),
            file: file,
            status: UploadStatus.pending,
            localAssetId: asset.id,
          );
          
          await _uploadLocalDataSource.addTask(task);
          
          // Mark as pending in the sync registry to avoid re-adding
          await _syncLocalDataSource.markPending(asset.id);
        }
      }

      return const Right(unit);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
