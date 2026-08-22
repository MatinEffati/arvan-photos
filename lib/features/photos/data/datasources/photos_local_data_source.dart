import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

abstract class PhotosLocalDataSource {
  Future<void> registerBackup({
    required String assetId,
    required String remoteKey,
    required String originalFilename,
  });
  Future<String?> getRemoteKey(String assetId);
  Future<void> removeBackup(String assetId);
}

@LazySingleton(as: PhotosLocalDataSource)
class PhotosLocalDataSourceImpl implements PhotosLocalDataSource {
  PhotosLocalDataSourceImpl(this._db);

  final Database _db;

  @override
  Future<void> registerBackup({
    required String assetId,
    required String remoteKey,
    required String originalFilename,
  }) async {
    await _db.insert(
      'backup_registry',
      {
        'asset_id': assetId,
        'remote_key': remoteKey,
        'original_filename': originalFilename,
        'synced_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<String?> getRemoteKey(String assetId) async {
    final results = await _db.query(
      'backup_registry',
      columns: ['remote_key'],
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );

    if (results.isEmpty) return null;
    return results.first['remote_key'] as String?;
  }

  @override
  Future<void> removeBackup(String assetId) async {
    await _db.delete(
      'backup_registry',
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );
  }
}
