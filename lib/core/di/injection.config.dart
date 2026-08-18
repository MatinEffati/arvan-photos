// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:arvan_photos/core/config/app_config.dart' as _i835;
import 'package:arvan_photos/core/database/database_module.dart' as _i62;
import 'package:arvan_photos/core/di/core_module.dart' as _i234;
import 'package:arvan_photos/core/di/repository_module.dart' as _i774;
import 'package:arvan_photos/core/network/arvan_s3_client.dart' as _i209;
import 'package:arvan_photos/features/photos/data/datasources/backup_local_datasource.dart'
    as _i485;
import 'package:arvan_photos/features/photos/data/datasources/device_gallery_datasource.dart'
    as _i916;
import 'package:arvan_photos/features/photos/data/datasources/photo_key_generator.dart'
    as _i871;
import 'package:arvan_photos/features/photos/data/datasources/photos_remote_data_source.dart'
    as _i540;
import 'package:arvan_photos/features/photos/data/datasources/photos_remote_data_source_impl.dart'
    as _i1058;
import 'package:arvan_photos/features/photos/data/datasources/sync_local_datasource.dart'
    as _i635;
import 'package:arvan_photos/features/photos/data/datasources/upload_local_datasource.dart'
    as _i638;
import 'package:arvan_photos/features/photos/data/repositories/photo_repository_impl.dart'
    as _i207;
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart'
    as _i666;
import 'package:arvan_photos/features/photos/domain/repositories/photo_query_repository.dart'
    as _i591;
import 'package:arvan_photos/features/photos/domain/usecases/delete_multiple_photos_usecase.dart'
    as _i470;
import 'package:arvan_photos/features/photos/domain/usecases/delete_photo_usecase.dart'
    as _i684;
import 'package:arvan_photos/features/photos/domain/usecases/edit_photo_usecase.dart'
    as _i410;
import 'package:arvan_photos/features/photos/domain/usecases/enqueue_backup_usecase.dart'
    as _i930;
import 'package:arvan_photos/features/photos/domain/usecases/get_photos_usecase.dart'
    as _i1014;
import 'package:arvan_photos/features/photos/domain/usecases/sync_gallery_usecase.dart'
    as _i340;
import 'package:arvan_photos/features/photos/domain/usecases/upload_photo_usecase.dart'
    as _i209;
import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_bloc.dart'
    as _i51;
import 'package:arvan_photos/features/photos/presentation/bloc/detail/photo_detail_cubit.dart'
    as _i225;
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart'
    as _i725;
import 'package:arvan_photos/features/photos/presentation/bloc/photos/photos_bloc.dart'
    as _i303;
import 'package:arvan_photos/features/photos/presentation/bloc/sync/sync_bloc.dart'
    as _i628;
import 'package:arvan_photos/features/photos/presentation/bloc/upload/upload_bloc.dart'
    as _i73;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:sqflite/sqflite.dart' as _i779;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final databaseModule = _$DatabaseModule();
    final coreModule = _$CoreModule();
    final repositoryModule = _$RepositoryModule();
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
    gh.lazySingleton<_i635.SyncLocalDataSource>(
      () => _i635.SyncLocalDataSourceImpl(gh<_i779.Database>()),
    );
    gh.lazySingleton<_i638.UploadLocalDataSource>(
      () => _i638.UploadLocalDataSourceImpl(gh<_i779.Database>()),
    );
    gh.lazySingleton<_i871.PhotoKeyGenerator>(
      () => _i871.S3PhotoKeyGenerator(),
    );
    gh.factory<_i73.UploadBloc>(
      () => _i73.UploadBloc(gh<_i638.UploadLocalDataSource>()),
    );
    gh.lazySingleton<_i540.PhotosRemoteDataSource>(
      () => _i1058.PhotosRemoteDataSourceImpl(gh<_i209.ArvanS3Client>()),
    );
    gh.factory<_i340.SyncGalleryUseCase>(
      () => _i340.SyncGalleryUseCase(
        gh<_i916.DeviceGalleryDataSource>(),
        gh<_i635.SyncLocalDataSource>(),
        gh<_i638.UploadLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i207.PhotoRepositoryImpl>(
      () => _i207.PhotoRepositoryImpl(
        gh<_i540.PhotosRemoteDataSource>(),
        gh<_i871.PhotoKeyGenerator>(),
        gh<_i635.SyncLocalDataSource>(),
        gh<_i485.BackupLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i591.PhotoQueryRepository>(
      () => repositoryModule.queryRepository(gh<_i207.PhotoRepositoryImpl>()),
    );
    gh.lazySingleton<_i666.PhotoCommandRepository>(
      () => repositoryModule.commandRepository(gh<_i207.PhotoRepositoryImpl>()),
    );
    gh.factory<_i628.SyncBloc>(
      () =>
          _i628.SyncBloc(gh<_i340.SyncGalleryUseCase>(), gh<_i73.UploadBloc>()),
    );
    gh.factory<_i1014.GetPhotosUseCase>(
      () => _i1014.GetPhotosUseCase(gh<_i591.PhotoQueryRepository>()),
    );
    gh.factory<_i930.EnqueueBackupUseCase>(
      () => _i930.EnqueueBackupUseCase(gh<_i666.PhotoCommandRepository>()),
    );
    gh.factory<_i51.BackupStatusBloc>(
      () => _i51.BackupStatusBloc(gh<_i666.PhotoCommandRepository>()),
    );
    gh.factory<_i470.DeleteMultiplePhotosUseCase>(
      () =>
          _i470.DeleteMultiplePhotosUseCase(gh<_i666.PhotoCommandRepository>()),
    );
    gh.factory<_i684.DeletePhotoUseCase>(
      () => _i684.DeletePhotoUseCase(gh<_i666.PhotoCommandRepository>()),
    );
    gh.factory<_i410.EditPhotoUseCase>(
      () => _i410.EditPhotoUseCase(gh<_i666.PhotoCommandRepository>()),
    );
    gh.factory<_i209.UploadPhotoUseCase>(
      () => _i209.UploadPhotoUseCase(gh<_i666.PhotoCommandRepository>()),
    );
    gh.factory<_i725.DeviceGalleryBloc>(
      () => _i725.DeviceGalleryBloc(
        gh<_i916.DeviceGalleryDataSource>(),
        gh<_i930.EnqueueBackupUseCase>(),
      ),
    );
    gh.factory<_i303.PhotosBloc>(
      () => _i303.PhotosBloc(
        gh<_i1014.GetPhotosUseCase>(),
        gh<_i470.DeleteMultiplePhotosUseCase>(),
      ),
    );
    gh.factory<_i225.PhotoDetailCubit>(
      () => _i225.PhotoDetailCubit(
        gh<_i684.DeletePhotoUseCase>(),
        gh<_i410.EditPhotoUseCase>(),
      ),
    );
    return this;
  }
}

class _$DatabaseModule extends _i62.DatabaseModule {}

class _$CoreModule extends _i234.CoreModule {}

class _$RepositoryModule extends _i774.RepositoryModule {}
