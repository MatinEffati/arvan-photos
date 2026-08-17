import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

// ignore_for_file: one_member_abstracts
abstract class PhotoKeyGenerator {
  String generateKey(String originalPath);
}

@LazySingleton(as: PhotoKeyGenerator)
class S3PhotoKeyGenerator implements PhotoKeyGenerator {
  final _uuid = const Uuid();

  @override
  String generateKey(String originalPath) {
    final fileName = originalPath.split('/').last;
    final extension = fileName.split('.').last;
    return 'photos/${_uuid.v4()}.$extension';
  }
}
