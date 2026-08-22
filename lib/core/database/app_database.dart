import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const int version = 9;
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
        await db.execute('''
          CREATE TABLE backup_registry (
            asset_id TEXT PRIMARY KEY,
            remote_key TEXT NOT NULL,
            original_filename TEXT NOT NULL,
            synced_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS backup_registry (
              asset_id TEXT PRIMARY KEY,
              remote_key TEXT NOT NULL,
              original_filename TEXT NOT NULL,
              synced_at TEXT NOT NULL
            )
          ''');
        }
      },
      onOpen: (db) async {
        // Robust opening.
      },
    );

    return _database!;
  }
}
