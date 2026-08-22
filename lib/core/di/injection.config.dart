// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:arvan_photos/core/config/app_config.dart' as _i835;
import 'package:arvan_photos/core/di/core_module.dart' as _i234;
import 'package:arvan_photos/core/di/database_module.dart' as _i42;
import 'package:arvan_photos/core/network/arvan_s3_client.dart' as _i209;
import 'package:arvan_photos/features/photos/data/datasources/device_gallery_datasource.dart'
    as _i916;
import 'package:arvan_photos/features/photos/data/datasources/photos_local_data_source.dart'
    as _i418;
import 'package:arvan_photos/features/photos/data/datasources/photos_remote_data_source.dart'
    as _i540;
import 'package:arvan_photos/features/photos/data/repositories/device_gallery_repository_impl.dart'
    as _i986;
import 'package:arvan_photos/features/photos/data/repositories/photos_repository_impl.dart'
    as _i119;
import 'package:arvan_photos/features/photos/domain/repositories/device_gallery_repository.dart'
    as _i52;
import 'package:arvan_photos/features/photos/domain/repositories/photos_repository.dart'
    as _i1016;
import 'package:arvan_photos/features/photos/domain/usecases/delete_photo_usecase.dart'
    as _i684;
import 'package:arvan_photos/features/photos/domain/usecases/get_asset_path_usecase.dart'
    as _i926;
import 'package:arvan_photos/features/photos/domain/usecases/get_local_gallery_usecase.dart'
    as _i586;
import 'package:arvan_photos/features/photos/domain/usecases/upload_photo_usecase.dart'
    as _i209;
import 'package:arvan_photos/features/photos/presentation/bloc/delete/delete_bloc.dart'
    as _i861;
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart'
    as _i725;
import 'package:arvan_photos/features/photos/presentation/bloc/upload/upload_bloc.dart'
    as _i73;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:sqflite/sqflite.dart' as _i779;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final coreModule = _$CoreModule();
    final databaseModule = _$DatabaseModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => coreModule.prefs,
      preResolve: true,
    );
    await gh.singletonAsync<_i779.Database>(
      () => databaseModule.database,
      preResolve: true,
    );
    gh.lazySingleton<_i835.AppConfig>(() => _i835.AppConfig());
    gh.lazySingleton<_i361.Dio>(() => coreModule.dio);
    gh.lazySingleton<_i418.PhotosLocalDataSource>(
      () => _i418.PhotosLocalDataSourceImpl(gh<_i779.Database>()),
    );
    gh.lazySingleton<_i916.DeviceGalleryDataSource>(
      () => _i916.DeviceGalleryDataSourceImpl(),
    );
    gh.lazySingleton<_i209.ArvanS3Client>(
      () => _i209.ArvanS3Client(gh<_i835.AppConfig>(), gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i52.DeviceGalleryRepository>(
      () => _i986.DeviceGalleryRepositoryImpl(
        gh<_i916.DeviceGalleryDataSource>(),
      ),
    );
    gh.factory<_i926.GetAssetPathUseCase>(
      () => _i926.GetAssetPathUseCase(gh<_i52.DeviceGalleryRepository>()),
    );
    gh.factory<_i586.GetLocalGalleryUseCase>(
      () => _i586.GetLocalGalleryUseCase(gh<_i52.DeviceGalleryRepository>()),
    );
    gh.lazySingleton<_i540.PhotosRemoteDataSource>(
      () => _i540.PhotosRemoteDataSourceImpl(gh<_i209.ArvanS3Client>()),
    );
    gh.factory<_i725.DeviceGalleryBloc>(
      () => _i725.DeviceGalleryBloc(
        gh<_i586.GetLocalGalleryUseCase>(),
        gh<_i460.SharedPreferences>(),
        gh<_i418.PhotosLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i1016.PhotosRepository>(
      () => _i119.PhotosRepositoryImpl(gh<_i540.PhotosRemoteDataSource>()),
    );
    gh.factory<_i684.DeletePhotoUseCase>(
      () => _i684.DeletePhotoUseCase(gh<_i1016.PhotosRepository>()),
    );
    gh.factory<_i209.UploadPhotoUseCase>(
      () => _i209.UploadPhotoUseCase(gh<_i1016.PhotosRepository>()),
    );
    gh.factory<_i861.DeleteBloc>(
      () => _i861.DeleteBloc(
        gh<_i684.DeletePhotoUseCase>(),
        gh<_i418.PhotosLocalDataSource>(),
      ),
    );
    gh.factory<_i73.UploadBloc>(
      () => _i73.UploadBloc(
        gh<_i209.UploadPhotoUseCase>(),
        gh<_i926.GetAssetPathUseCase>(),
        gh<_i418.PhotosLocalDataSource>(),
      ),
    );
    return this;
  }
}

class _$CoreModule extends _i234.CoreModule {}

class _$DatabaseModule extends _i42.DatabaseModule {}
