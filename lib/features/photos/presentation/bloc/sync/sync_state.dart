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
    this.individualProgress = 0.0,
  });

  final int current;
  final int total;
  final double individualProgress;

  double get progress {
    if (total <= 0) return 0;
    // محاسبه پیشرفت کل: فایل‌های قبلی + پیشرفت فایل فعلی
    return (current + individualProgress) / total;
  }

  @override
  List<Object?> get props => [current, total, individualProgress];
}

class SyncCompleted extends SyncState {}

class SyncFailure extends SyncState {
  const SyncFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
