import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const int version = 7;
  static const String name = 'arvan_photos.db';

  static Database? _database;

  static Future<Database> open() async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, name);

    _database = await openDatabase(
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
          try {
            await db.execute('ALTER TABLE upload_tasks ADD COLUMN local_asset_id TEXT');
          } catch (_) {}
        }
        if (oldVersion < 6) {
          await _createBackupQueueTable(db);
        }
        if (oldVersion < 7) {
          try {
            await db.execute('ALTER TABLE backup_queue ADD COLUMN file_path TEXT');
          } catch (_) {}
        }
      },
    );

    // After opening the database, ensure all columns exist (robust migration)
    await _database?.execute('ALTER TABLE backup_queue ADD COLUMN file_path TEXT').catchError((_) => null);

    // After opening the database, reset any tasks stuck in 'uploading' state.
    // This handles recovery after app crashes or forced stops.
    await _database?.transaction((txn) async {
      await txn.update(
        'backup_queue',
        {'status': 'queued'},
        where: 'status = ?',
        whereArgs: ['uploading'],
      );
      await txn.update(
        'upload_tasks',
        {'status': 'pending'}, // Status name from UploadStatus enum
        where: 'status = ?',
        whereArgs: ['uploading'],
      );
    });

    return _database!;
  }

  static Future<void> _createSyncRegistryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_registry (
        local_asset_id TEXT PRIMARY KEY,
        remote_key TEXT,
        status TEXT NOT NULL,
        synced_at TEXT
      )
    ''');
  }

  static Future<void> _createUploadTasksTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS upload_tasks (
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
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS backup_queue (
          local_asset_id TEXT PRIMARY KEY,
          remote_key TEXT,
          file_path TEXT,
          status TEXT NOT NULL,
          progress REAL DEFAULT 0,
          queued_at TEXT,
          synced_at TEXT
        )
      ''');
    } catch (_) {}
  }
}
