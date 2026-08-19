import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/domain/entities/upload_task.dart';
import 'package:dartz/dartz.dart';

abstract class UploadRepository {
  Future<Either<Failure, Unit>> addTask(UploadTask task);
  Future<List<UploadTask>> getAllTasks();
  Future<void> deleteAllTasks();
}
