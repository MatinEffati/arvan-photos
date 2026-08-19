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
import 'package:arvan_photos/core/di/repository_module.dart' as _i774;
import 'package:arvan_photos/core/network/arvan_s3_client.dart' as _i209;
import 'package:arvan_photos/features/cloud/data/datasources/cloud_remote_data_source.dart'
    as _i733;
import 'package:arvan_photos/features/cloud/data/repositories/cloud_repository_impl.dart'
    as _i342;
import 'package:arvan_photos/features/cloud/domain/repositories/cloud_repository.dart'
    as _i914;
import 'package:arvan_photos/features/cloud/domain/usecases/get_cloud_photos.dart'
    as _i717;
import 'package:arvan_photos/features/cloud/presentation/bloc/cloud_bloc.dart'
    as _i833;
import 'package:arvan_photos/features/photos/data/datasources/backup_local_datasource.dart'
    as _i485;
import 'package:arvan_photos/features/photos/data/datasources/device_gallery_datasource.dart'
    as _i916;
import 'package:arvan_photos/features/photos/data/datasources/photo_key_generator.dart'
    as _i871;
import 'package:arvan_photos/features/photos/data/datasources/upload_local_datasource.dart'
    as _i638;
import 'package:arvan_photos/features/photos/data/repositories/device_gallery_repository_impl.dart'
    as _i986;
import 'package:arvan_photos/features/photos/data/repositories/photo_repository_impl.dart'
    as _i207;
import 'package:arvan_photos/features/photos/data/repositories/upload_repository_impl.dart'
    as _i102;
import 'package:arvan_photos/features/photos/domain/repositories/device_gallery_repository.dart'
    as _i52;
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart'
    as _i666;
import 'package:arvan_photos/features/photos/domain/repositories/photo_query_repository.dart'
    as _i591;
import 'package:arvan_photos/features/photos/domain/repositories/upload_repository.dart'
    as _i1003;
import 'package:arvan_photos/features/photos/domain/usecases/delete_backup_from_cloud_usecase.dart'
    as _i123;
import 'package:arvan_photos/features/photos/domain/usecases/delete_photo_usecase.dart'
    as _i684;
import 'package:arvan_photos/features/photos/domain/usecases/edit_photo_usecase.dart'
    as _i410;
import 'package:arvan_photos/features/photos/domain/usecases/enqueue_backup_usecase.dart'
    as _i930;
import 'package:arvan_photos/features/photos/domain/usecases/enqueue_upload_usecase.dart'
    as _i744;
import 'package:arvan_photos/features/photos/domain/usecases/get_asset_path_usecase.dart'
    as _i926;
import 'package:arvan_photos/features/photos/domain/usecases/get_backup_status_usecase.dart'
    as _i66;
import 'package:arvan_photos/features/photos/domain/usecases/get_cloud_count_usecase.dart'
    as _i1005;
import 'package:arvan_photos/features/photos/domain/usecases/get_local_gallery_usecase.dart'
    as _i586;
import 'package:arvan_photos/features/photos/domain/usecases/get_synced_ids_usecase.dart'
    as _i183;
import 'package:arvan_photos/features/photos/domain/usecases/get_upload_tasks_usecase.dart'
    as _i789;
import 'package:arvan_photos/features/photos/domain/usecases/watch_backup_status_usecase.dart'
    as _i562;
import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_bloc.dart'
    as _i51;
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
    final repositoryModule = _$RepositoryModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => coreModule.prefs,
      preResolve: true,
    );
    await gh.factoryAsync<_i779.Database>(
      () => databaseModule.database,
      preResolve: true,
    );
    gh.lazySingleton<_i835.AppConfig>(() => _i835.AppConfig());
    gh.lazySingleton<_i361.Dio>(() => coreModule.dio);
    gh.lazySingleton<_i209.ArvanS3Client>(
      () => _i209.ArvanS3Client(gh<_i361.Dio>(), gh<_i835.AppConfig>()),
    );
    gh.lazySingleton<_i485.BackupLocalDataSource>(
      () => _i485.BackupLocalDataSourceImpl(gh<_i779.Database>()),
    );
    gh.lazySingleton<_i916.DeviceGalleryDataSource>(
      () => _i916.DeviceGalleryDataSourceImpl(),
    );
    gh.lazySingleton<_i638.UploadLocalDataSource>(
      () => _i638.UploadLocalDataSourceImpl(gh<_i779.Database>()),
    );
    gh.lazySingleton<_i871.PhotoKeyGenerator>(
      () => _i871.S3PhotoKeyGenerator(),
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
    gh.lazySingleton<_i1003.UploadRepository>(
      () => _i102.UploadRepositoryImpl(gh<_i638.UploadLocalDataSource>()),
    );
    gh.lazySingleton<_i733.CloudRemoteDataSource>(
      () => _i733.CloudRemoteDataSourceImpl(gh<_i209.ArvanS3Client>()),
    );
    gh.factory<_i744.EnqueueUploadUseCase>(
      () => _i744.EnqueueUploadUseCase(gh<_i1003.UploadRepository>()),
    );
    gh.factory<_i789.GetUploadTasksUseCase>(
      () => _i789.GetUploadTasksUseCase(gh<_i1003.UploadRepository>()),
    );
    gh.lazySingleton<_i207.PhotoRepositoryImpl>(
      () => _i207.PhotoRepositoryImpl(
        gh<_i733.CloudRemoteDataSource>(),
        gh<_i871.PhotoKeyGenerator>(),
        gh<_i485.BackupLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i914.CloudRepository>(
      () => _i342.CloudRepositoryImpl(gh<_i733.CloudRemoteDataSource>()),
    );
    gh.factory<_i73.UploadBloc>(
      () => _i73.UploadBloc(
        gh<_i744.EnqueueUploadUseCase>(),
        gh<_i789.GetUploadTasksUseCase>(),
      ),
    );
    gh.lazySingleton<_i591.PhotoQueryRepository>(
      () => repositoryModule.queryRepository(gh<_i207.PhotoRepositoryImpl>()),
    );
    gh.lazySingleton<_i666.PhotoCommandRepository>(
      () => repositoryModule.commandRepository(gh<_i207.PhotoRepositoryImpl>()),
    );
    gh.factory<_i123.DeleteBackupFromCloudUseCase>(
      () => _i123.DeleteBackupFromCloudUseCase(
        gh<_i666.PhotoCommandRepository>(),
      ),
    );
    gh.factory<_i930.EnqueueBackupUseCase>(
      () => _i930.EnqueueBackupUseCase(gh<_i666.PhotoCommandRepository>()),
    );
    gh.factory<_i66.GetBackupStatusUseCase>(
      () => _i66.GetBackupStatusUseCase(gh<_i666.PhotoCommandRepository>()),
    );
    gh.factory<_i183.GetSyncedIdsUseCase>(
      () => _i183.GetSyncedIdsUseCase(gh<_i666.PhotoCommandRepository>()),
    );
    gh.factory<_i562.WatchBackupStatusUseCase>(
      () => _i562.WatchBackupStatusUseCase(gh<_i666.PhotoCommandRepository>()),
    );
    gh.factory<_i51.BackupStatusBloc>(
      () => _i51.BackupStatusBloc(gh<_i666.PhotoCommandRepository>()),
    );
    gh.lazySingleton<_i717.GetCloudPhotos>(
      () => _i717.GetCloudPhotos(gh<_i914.CloudRepository>()),
    );
    gh.factory<_i684.DeletePhotoUseCase>(
      () => _i684.DeletePhotoUseCase(gh<_i666.PhotoCommandRepository>()),
    );
    gh.factory<_i410.EditPhotoUseCase>(
      () => _i410.EditPhotoUseCase(gh<_i666.PhotoCommandRepository>()),
    );
    gh.factory<_i1005.GetCloudCountUseCase>(
      () => _i1005.GetCloudCountUseCase(gh<_i591.PhotoQueryRepository>()),
    );
    gh.factory<_i833.CloudBloc>(
      () => _i833.CloudBloc(gh<_i717.GetCloudPhotos>()),
    );
    gh.factory<_i725.DeviceGalleryBloc>(
      () => _i725.DeviceGalleryBloc(
        gh<_i586.GetLocalGalleryUseCase>(),
        gh<_i66.GetBackupStatusUseCase>(),
        gh<_i183.GetSyncedIdsUseCase>(),
        gh<_i926.GetAssetPathUseCase>(),
        gh<_i1005.GetCloudCountUseCase>(),
        gh<_i930.EnqueueBackupUseCase>(),
        gh<_i123.DeleteBackupFromCloudUseCase>(),
        gh<_i562.WatchBackupStatusUseCase>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    return this;
  }
}

class _$CoreModule extends _i234.CoreModule {}

class _$DatabaseModule extends _i42.DatabaseModule {}

class _$RepositoryModule extends _i774.RepositoryModule {}
