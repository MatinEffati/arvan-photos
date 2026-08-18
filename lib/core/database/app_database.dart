import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const int version = 4;
  static const String name = 'arvan_photos.db';

  static Future<Database> open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, name);

    return openDatabase(
      path,
      version: version,
      onCreate: (db, version) async {
        await _createSyncRegistryTable(db);
        await _createUploadTasksTable(db);
        await _createBackupQueueTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createUploadTasksTable(db);
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE upload_tasks ADD COLUMN local_asset_id TEXT');
        }
        if (oldVersion < 4) {
          await _createBackupQueueTable(db);
        }
      },
    );
  }

  static Future<void> _createSyncRegistryTable(Database db) async {
    await db.execute('''
      CREATE TABLE sync_registry (
        local_asset_id TEXT PRIMARY KEY,
        remote_key TEXT,
        status TEXT NOT NULL,
        synced_at TEXT
      )
    ''');
  }

  static Future<void> _createUploadTasksTable(Database db) async {
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

  static Future<void> _createBackupQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE backup_queue (
        local_asset_id TEXT PRIMARY KEY,
        remote_key TEXT,
        status TEXT NOT NULL,
        progress REAL DEFAULT 0,
        queued_at TEXT,
        synced_at TEXT
      )
    ''');
  }
}
