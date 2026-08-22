import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AppConfig {
  String get arvanEndpoint => dotenv.env['ARVAN_ENDPOINT'] ?? '';
  String get arvanRegion => dotenv.env['ARVAN_REGION'] ?? '';
  String get arvanAccessKey => dotenv.env['ARVAN_ACCESS_KEY'] ?? '';
  String get arvanSecretKey => dotenv.env['ARVAN_SECRET_KEY'] ?? '';
  String get arvanBucket => dotenv.env['ARVAN_BUCKET'] ?? '';
  
  bool get isDebug => dotenv.env['DEBUG'] == 'true';
}
