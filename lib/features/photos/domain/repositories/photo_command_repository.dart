import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/entities/backup_status.dart';
import 'package:arvan_photos/features/photos/domain/entities/upload_cancel_token.dart';
import 'package:dartz/dartz.dart';

abstract class PhotoCommandRepository {
  Future<Either<Failure, String>> uploadPhoto(
    String filePath, {
    void Function(double progress)? onProgress,
    UploadCancelToken? cancelToken,
  });
  Future<Either<Failure, Unit>> deletePhoto(String key);
  Future<Either<Failure, Unit>> deleteMultiplePhotos(List<String> keys);
  Future<Either<Failure, Unit>> editPhoto(String key, String editedFilePath);

  Future<Either<Failure, Unit>> enqueueBackup(List<Map<String, String>> assets);
  Future<Either<Failure, Unit>> deleteBackup(List<String> assetIds);
  Stream<Map<String, dynamic>> watchBackupStatus(); 
  Future<List<BackupStatus>> getAllBackupStatuses();
  Future<List<String>> getSyncedIds();
}
