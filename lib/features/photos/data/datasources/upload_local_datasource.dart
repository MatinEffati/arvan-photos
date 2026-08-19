import 'dart:io';
import 'package:arvan_photos/features/photos/domain/entities/upload_task.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

abstract class UploadLocalDataSource {
  Future<void> addTask(UploadTask task);
  Future<void> updateTask(UploadTask task);
  Future<void> deleteTask(String taskId);
  Future<void> deleteAllTasks();
  Future<List<UploadTask>> getAllTasks();
  Future<UploadTask?> getNextPendingTask();
}

@LazySingleton(as: UploadLocalDataSource)
class UploadLocalDataSourceImpl implements UploadLocalDataSource {
  UploadLocalDataSourceImpl(this._db);
  final Database _db;

  @override
  Future<void> addTask(UploadTask task) async {
    await _db.insert(
      'upload_tasks',
      {
        'id': task.id,
        'file_path': task.filePath,
        'progress': task.progress,
        'status': task.status.name,
        'error_message': task.errorMessage,
        'local_asset_id': task.localAssetId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateTask(UploadTask task) async {
    await _db.update(
      'upload_tasks',
      {
        'progress': task.progress,
        'status': task.status.name,
        'error_message': task.errorMessage,
        'local_asset_id': task.localAssetId,
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _db.delete('upload_tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  @override
  Future<void> deleteAllTasks() async {
    await _db.delete('upload_tasks');
  }

  @override
  Future<List<UploadTask>> getAllTasks() async {
    final maps = await _db.query('upload_tasks');
    return maps.map((map) => UploadTask(
      id: map['id'] as String,
      filePath: map['file_path'] as String,
      progress: map['progress'] as double,
      status: UploadStatus.values.firstWhere((e) => e.name == map['status']),
      errorMessage: map['error_message'] as String?,
      localAssetId: map['local_asset_id'] as String?,
    )).toList();
  }

  @override
  Future<UploadTask?> getNextPendingTask() async {
    final maps = await _db.query(
      'upload_tasks',
      where: 'status = ?',
      whereArgs: [UploadStatus.pending.name],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final map = maps.first;
    return UploadTask(
      id: map['id'] as String,
      filePath: map['file_path'] as String,
      progress: map['progress'] as double,
      status: UploadStatus.pending,
      errorMessage: map['error_message'] as String?,
      localAssetId: map['local_asset_id'] as String?,
    );
  }
}
