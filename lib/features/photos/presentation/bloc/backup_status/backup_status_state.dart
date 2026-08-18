import 'package:equatable/equatable.dart';

class BackupStatusState extends Equatable {
  final Map<String, Map<String, dynamic>> statuses;

  const BackupStatusState({this.statuses = const {}});

  BackupStatusState copyWith({
    Map<String, Map<String, dynamic>>? statuses,
  }) {
    return BackupStatusState(
      statuses: statuses ?? this.statuses,
    );
  }

  @override
  List<Object?> get props => [statuses];
}
