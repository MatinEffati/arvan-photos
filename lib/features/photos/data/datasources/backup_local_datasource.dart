import 'package:arvan_photos/features/photos/data/models/backup_queue_item.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

abstract class BackupLocalDataSource {
  Future<void> enqueue(List<Map<String, String>> assets);
  Future<void> updateStatus(String assetId, String status, {double? progress, String? remoteKey});
  Future<List<BackupQueueItem>> getAll();
  Future<List<BackupQueueItem>> getPending(int limit);
  Future<BackupQueueItem?> getById(String assetId);
  Future<List<String>> getSyncedIds();
  Future<void> remove(String assetId);
}

@LazySingleton(as: BackupLocalDataSource)
class BackupLocalDataSourceImpl implements BackupLocalDataSource {
  BackupLocalDataSourceImpl(this._db);

  final Database _db;
  static const String _tableName = 'backup_queue';

  @override
  Future<void> enqueue(List<Map<String, String>> assets) async {
    final now = DateTime.now().toIso8601String();
    final syncedIds = await getSyncedIds();
    final syncedIdsSet = syncedIds.toSet();

    final batch = _db.batch();
    for (final asset in assets) {
      final id = asset['id']!;
      final path = asset['path']!;
      
      if (syncedIdsSet.contains(id)) continue;

      batch.insert(
        _tableName,
        {
          'local_asset_id': id,
          'file_path': path,
          'status': 'queued',
          'progress': 0.0,
          'queued_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateStatus(
    String assetId,
    String status, {
    double? progress,
    String? remoteKey,
  }) async {
    final Map<String, dynamic> values = {
      'status': status,
    };
    if (progress != null) values['progress'] = progress;
    if (remoteKey != null) values['remote_key'] = remoteKey;
    if (status == 'synced') values['synced_at'] = DateTime.now().toIso8601String();

    await _db.update(
      _tableName,
      values,
      where: 'local_asset_id = ?',
      whereArgs: [assetId],
    );
  }

  @override
  Future<List<BackupQueueItem>> getAll() async {
    final maps = await _db.query(_tableName);
    return maps.map((e) => BackupQueueItem.fromMap(e)).toList();
  }

  @override
  Future<List<BackupQueueItem>> getPending(int limit) async {
    final maps = await _db.query(
      _tableName,
      where: 'status = ? OR status = ?',
      whereArgs: ['queued', 'failed'],
      limit: limit,
      orderBy: 'queued_at ASC',
    );
    return maps.map((e) => BackupQueueItem.fromMap(e)).toList();
  }

  @override
  Future<BackupQueueItem?> getById(String assetId) async {
    final results = await _db.query(
      _tableName,
      where: 'local_asset_id = ?',
      whereArgs: [assetId],
    );
    return results.isNotEmpty ? BackupQueueItem.fromMap(results.first) : null;
  }

  @override
  Future<List<String>> getSyncedIds() async {
    final results = await _db.query(
      _tableName,
      columns: ['local_asset_id'],
      where: 'status = ?',
      whereArgs: ['synced'],
    );
    return results.map((e) => e['local_asset_id'] as String).toList();
  }

  @override
  Future<void> remove(String assetId) async {
    await _db.delete(
      _tableName,
      where: 'local_asset_id = ?',
      whereArgs: [assetId],
    );
  }
}
