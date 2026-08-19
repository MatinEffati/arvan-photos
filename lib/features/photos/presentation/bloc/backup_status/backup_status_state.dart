import 'package:arvan_photos/features/photos/domain/entities/backup_status.dart';
import 'package:equatable/equatable.dart';

class BackupStatusState extends Equatable {
  final Map<String, BackupStatus> statuses;

  const BackupStatusState({this.statuses = const {}});

  BackupStatusState copyWith({
    Map<String, BackupStatus>? statuses,
  }) {
    return BackupStatusState(
      statuses: statuses ?? this.statuses,
    );
  }

  @override
  List<Object?> get props => [statuses];
}
