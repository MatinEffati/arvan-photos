import 'package:arvan_photos/core/database/app_database.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@module
abstract class DatabaseModule {
  @preResolve
  Future<Database> get database => AppDatabase.open();
}
