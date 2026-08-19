import 'package:equatable/equatable.dart';

class BackupStatus extends Equatable {
  final String assetId;
  final String status;
  final double progress;
  final String? remoteKey;

  const BackupStatus({
    required this.assetId,
    required this.status,
    this.progress = 0.0,
    this.remoteKey,
  });

  @override
  List<Object?> get props => [assetId, status, progress, remoteKey];
}
