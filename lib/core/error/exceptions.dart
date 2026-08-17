class ServerException implements Exception {
  ServerException({this.message, this.statusCode});

  final String? message;
  final int? statusCode;

  @override
  String toString() => 'ServerException: $message ($statusCode)';
}

class NetworkException implements Exception {
  NetworkException({this.message});

  final String? message;

  @override
  String toString() => 'NetworkException: $message';
}

class PermissionException implements Exception {
  PermissionException({this.message});

  final String? message;

  @override
  String toString() => 'PermissionException: $message';
}

class CacheException implements Exception {}
