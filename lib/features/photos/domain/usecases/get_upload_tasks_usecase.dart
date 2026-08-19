import 'package:arvan_photos/features/photos/domain/entities/upload_task.dart';
import 'package:arvan_photos/features/photos/domain/repositories/upload_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetUploadTasksUseCase {
  GetUploadTasksUseCase(this._repository);

  final UploadRepository _repository;

  Future<List<UploadTask>> call() {
    return _repository.getAllTasks();
  }

  Future<void> clearAll() {
    return _repository.deleteAllTasks();
  }
}
