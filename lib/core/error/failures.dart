import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([this.message = '']);
  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No Internet Connection']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission Denied']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unknown error occurred']);
}
