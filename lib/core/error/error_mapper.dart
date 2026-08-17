import 'package:dio/dio.dart';
import 'failures.dart';

class ErrorMapper {
  static Failure map(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return const NetworkFailure();
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 403) {
            return const PermissionFailure('Access Denied (403)');
          } else if (statusCode == 404) {
            return const ServerFailure('Resource Not Found (404)');
          } else if (statusCode != null && statusCode >= 500) {
            return ServerFailure('Internal Server Error ($statusCode)');
          }
          return ServerFailure('Server Error ($statusCode)');
        default:
          return const UnknownFailure();
      }
    }
    return UnknownFailure(error.toString());
  }
}
