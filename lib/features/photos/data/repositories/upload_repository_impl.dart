import 'package:arvan_photos/core/error/error_mapper.dart';
import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/data/datasources/upload_local_datasource.dart';
import 'package:arvan_photos/features/photos/domain/entities/upload_task.dart';
import 'package:arvan_photos/features/photos/domain/repositories/upload_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: UploadRepository)
class UploadRepositoryImpl implements UploadRepository {
  UploadRepositoryImpl(this._localDataSource);

  final UploadLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, Unit>> addTask(UploadTask task) async {
    try {
      await _localDataSource.addTask(task);
      return const Right(unit);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<List<UploadTask>> getAllTasks() {
    return _localDataSource.getAllTasks();
  }

  @override
  Future<void> deleteAllTasks() {
    return _localDataSource.deleteAllTasks();
  }
}
