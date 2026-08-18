import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

abstract class BackupLocalDataSource {
  Future<void> enqueue(List<String> assetIds);
  Future<void> updateStatus(String assetId, String status, {double? progress, String? remoteKey});
  Future<List<Map<String, dynamic>>> getAll();
  Future<List<Map<String, dynamic>>> getPending(int limit);
  Future<Map<String, dynamic>?> getById(String assetId);
}

@LazySingleton(as: BackupLocalDataSource)
class BackupLocalDataSourceImpl implements BackupLocalDataSource {
  BackupLocalDataSourceImpl(this._db);

  final Database _db;
  static const String _tableName = 'backup_queue';

  @override
  Future<void> enqueue(List<String> assetIds) async {
    final batch = _db.batch();
    final now = DateTime.now().toIso8601String();
    
    for (final id in assetIds) {
      batch.insert(
        _tableName,
        {
          'local_asset_id': id,
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
  Future<List<Map<String, dynamic>>> getAll() async {
    return _db.query(_tableName);
  }

  @override
  Future<List<Map<String, dynamic>>> getPending(int limit) async {
    return _db.query(
      _tableName,
      where: 'status = ? OR status = ?',
      whereArgs: ['queued', 'failed'],
      limit: limit,
      orderBy: 'queued_at ASC',
    );
  }

  @override
  Future<Map<String, dynamic>?> getById(String assetId) async {
    final results = await _db.query(
      _tableName,
      where: 'local_asset_id = ?',
      whereArgs: [assetId],
    );
    return results.isNotEmpty ? results.first : null;
  }
}
