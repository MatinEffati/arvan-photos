import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

abstract class SyncLocalDataSource {
  Future<String?> getStatus(String assetId);
  Future<void> markSynced(String assetId, String remoteKey);
  Future<void> markPending(String assetId);
  Future<void> markFailed(String assetId);
  Future<List<String>> getAllSyncedIds();
}

@LazySingleton(as: SyncLocalDataSource)
class SyncLocalDataSourceImpl implements SyncLocalDataSource {
  SyncLocalDataSourceImpl(this._db);

  final Database _db;

  @override
  Future<String?> getStatus(String assetId) async {
    final results = await _db.query(
      'sync_registry',
      columns: ['status'],
      where: 'local_asset_id = ?',
      whereArgs: [assetId],
    );
    if (results.isEmpty) return null;
    return results.first['status'] as String?;
  }

  @override
  Future<void> markSynced(String assetId, String remoteKey) async {
    await _db.insert(
      'sync_registry',
      {
        'local_asset_id': assetId,
        'remote_key': remoteKey,
        'status': 'synced',
        'synced_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> markPending(String assetId) async {
    await _db.insert(
      'sync_registry',
      {
        'local_asset_id': assetId,
        'status': 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> markFailed(String assetId) async {
    await _db.insert(
      'sync_registry',
      {
        'local_asset_id': assetId,
        'status': 'failed',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<String>> getAllSyncedIds() async {
    final results = await _db.query(
      'sync_registry',
      columns: ['local_asset_id'],
      where: 'status = ?',
      whereArgs: ['synced'],
    );
    return results.map((e) => e['local_asset_id']! as String).toList();
  }
}
