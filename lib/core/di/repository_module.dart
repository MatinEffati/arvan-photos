import 'package:arvan_photos/features/photos/data/repositories/photo_repository_impl.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_query_repository.dart';
import 'package:injectable/injectable.dart';

@module
abstract class RepositoryModule {
  @lazySingleton
  PhotoQueryRepository queryRepository(PhotoRepositoryImpl impl) => impl;

  @lazySingleton
  PhotoCommandRepository commandRepository(PhotoRepositoryImpl impl) => impl;
}
