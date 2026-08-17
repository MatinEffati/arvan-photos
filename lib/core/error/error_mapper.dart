import 'package:arvan_photos/core/error/exceptions.dart';
import 'package:arvan_photos/core/error/failures.dart';

class ErrorMapper {
  static Failure map(Object error) {
    if (error is NetworkException) {
      return const NetworkFailure();
    }
    
    if (error is PermissionException) {
      return PermissionFailure(error.message ?? 'Access Denied');
    }
    
    if (error is ServerException) {
      return ServerFailure(error.message ?? 'Server Error');
    }
    
    if (error is CacheException) {
      return const CacheFailure();
    }

    return UnknownFailure(error.toString());
  }
}
