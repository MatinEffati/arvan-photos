import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

abstract class BackupLocalDataSource {
  Future<void> enqueue(List<Map<String, String>> assets);
  Future<void> updateStatus(String assetId, String status, {double? progress, String? remoteKey});
  Future<List<Map<String, dynamic>>> getAll();
  Future<List<Map<String, dynamic>>> getPending(int limit);
  Future<Map<String, dynamic>?> getById(String assetId);
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
    
    await _db.transaction((txn) async {
      for (final asset in assets) {
        final id = asset['id']!;
        final path = asset['path']!;

        // Only insert if not exists, or update if status is NOT 'synced'
        final existing = await txn.query(
          _tableName,
          columns: ['status'],
          where: 'local_asset_id = ?',
          whereArgs: [id],
        );

        if (existing.isEmpty) {
          await txn.insert(_tableName, {
            'local_asset_id': id,
            'file_path': path,
            'status': 'queued',
            'progress': 0.0,
            'queued_at': now,
          });
        } else {
          final status = existing.first['status'] as String;
          if (status != 'synced') {
            await txn.update(
              _tableName,
              {
                'file_path': path,
                'status': 'queued',
                'progress': 0.0,
                'queued_at': now,
              },
              where: 'local_asset_id = ?',
              whereArgs: [id],
            );
          }
        }
      }
    });
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
