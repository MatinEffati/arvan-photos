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
        // Local-only app: no cloud tables needed.
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migrations removed as cloud functionality is deleted.
      },
      onOpen: (db) async {
        // Robust opening.
      },
    );

    return _database!;
  }
}
