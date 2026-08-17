import 'package:equatable/equatable.dart';

abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncIdle extends SyncState {}

class SyncInProgress extends SyncState {
  const SyncInProgress({
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  double get progress => total > 0 ? current / total : 0;

  @override
  List<Object?> get props => [current, total];
}

class SyncCompleted extends SyncState {}

class SyncFailure extends SyncState {
  const SyncFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
