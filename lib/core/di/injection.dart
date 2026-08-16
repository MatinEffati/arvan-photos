import 'package:arvan_photos/core/di/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  asExtension: true,
)
void configureDependencies() => getIt.init();
