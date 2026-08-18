import 'package:injectable/injectable.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

@module
abstract class DatabaseModule {
  @preResolve
  Future<Database> get database async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'arvan_photos.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sync_registry (
            local_asset_id TEXT PRIMARY KEY,
            remote_key TEXT,
            status TEXT NOT NULL,
            synced_at TEXT
          )
        ''');
        await _createUploadTasksTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createUploadTasksTable(db);
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE upload_tasks ADD COLUMN local_asset_id TEXT');
        }
      },
    );
  }

  Future<void> _createUploadTasksTable(Database db) async {
    await db.execute('''
      CREATE TABLE upload_tasks (
        id TEXT PRIMARY KEY,
        file_path TEXT NOT NULL,
        progress REAL NOT NULL,
        status TEXT NOT NULL,
        error_message TEXT,
        local_asset_id TEXT
      )
    ''');
  }
}
