// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:arvan_photos/core/di/core_module.dart' as _i234;
import 'package:arvan_photos/core/di/repository_module.dart' as _i774;
import 'package:arvan_photos/features/photos/data/datasources/arvan_s3_client.dart'
    as _i273;
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
import 'package:arvan_photos/features/photos/domain/usecases/get_photos_usecase.dart'
    as _i1014;
import 'package:arvan_photos/features/photos/domain/usecases/upload_photo_usecase.dart'
    as _i209;
import 'package:arvan_photos/features/photos/presentation/bloc/detail/photo_detail_cubit.dart'
    as _i225;
import 'package:arvan_photos/features/photos/presentation/bloc/photos/photos_bloc.dart'
    as _i303;
import 'package:arvan_photos/features/photos/presentation/bloc/upload/upload_bloc.dart'
    as _i73;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final coreModule = _$CoreModule();
    final repositoryModule = _$RepositoryModule();
    gh.lazySingleton<_i361.Dio>(() => coreModule.dio);
    gh.lazySingleton<_i273.ArvanS3Client>(
      () => _i273.ArvanS3Client(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i207.PhotoRepositoryImpl>(
      () => _i207.PhotoRepositoryImpl(gh<_i273.ArvanS3Client>()),
    );
    gh.lazySingleton<_i591.PhotoQueryRepository>(
      () => repositoryModule.queryRepository(gh<_i207.PhotoRepositoryImpl>()),
    );
    gh.lazySingleton<_i666.PhotoCommandRepository>(
      () => repositoryModule.commandRepository(gh<_i207.PhotoRepositoryImpl>()),
    );
    gh.factory<_i1014.GetPhotosUseCase>(
      () => _i1014.GetPhotosUseCase(gh<_i591.PhotoQueryRepository>()),
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
    gh.factory<_i73.UploadBloc>(
      () => _i73.UploadBloc(gh<_i209.UploadPhotoUseCase>()),
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

class _$CoreModule extends _i234.CoreModule {}

class _$RepositoryModule extends _i774.RepositoryModule {}
