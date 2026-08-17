import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/data/datasources/device_gallery_datasource.dart';
import 'package:arvan_photos/features/photos/data/datasources/sync_local_datasource.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
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
          // گزارش شروع آپلود فایل فعلی (current = i)
          onProgress?.call(i, toSync.length, 0.0);

          final result = await _commandRepository.uploadPhoto(
            file,
            onProgress: (individualProgress) {
              onProgress?.call(i, toSync.length, individualProgress);
            },
          );
          
          await result.fold(
            (failure) async => await _syncLocalDataSource.markFailed(asset.id),
            (_) async {
              await _syncLocalDataSource.markSynced(asset.id, 'synced_${asset.id}');
              // بعد از اتمام آپلود این فایل، پیشرفت آن را 1.0 گزارش می‌دهیم
              onProgress?.call(i, toSync.length, 1.0);
            },
          );
        }
      }

      return const Right(unit);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
