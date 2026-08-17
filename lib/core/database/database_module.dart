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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sync_registry (
            local_asset_id TEXT PRIMARY KEY,
            remote_key TEXT,
            status TEXT NOT NULL,
            synced_at TEXT
          )
        ''');
      },
    );
  }
}
