import 'package:equatable/equatable.dart';

abstract class BackupStatusEvent extends Equatable {
  const BackupStatusEvent();

  @override
  List<Object?> get props => [];
}

class BackupStatusStarted extends BackupStatusEvent {}

class BackupStatusUpdated extends BackupStatusEvent {
  final Map<String, dynamic> status;

  const BackupStatusUpdated(this.status);

  @override
  List<Object?> get props => [status];
}
