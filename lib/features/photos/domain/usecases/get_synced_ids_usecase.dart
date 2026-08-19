import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetSyncedIdsUseCase {
  GetSyncedIdsUseCase(this._repository);
  final PhotoCommandRepository _repository;

  Future<List<String>> call() {
    return _repository.getSyncedIds();
  }
}
