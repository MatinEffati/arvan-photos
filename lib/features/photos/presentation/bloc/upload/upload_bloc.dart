import 'dart:async';
import 'dart:io';
import 'package:arvan_photos/core/services/notification_service.dart';
import 'package:arvan_photos/features/photos/data/datasources/upload_local_datasource.dart';
import 'package:arvan_photos/features/photos/domain/entities/upload_task.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

part 'upload_event.dart';

part 'upload_state.dart';

@injectable
class UploadBloc extends Bloc<UploadEvent, UploadState> {
  UploadBloc(this._localDataSource) : super(UploadInitial()) {
    on<UploadStarted>(_onUploadStarted);
    on<UploadTaskUpdated>(_onUploadTaskUpdated);
    on<UploadResetRequested>(_onUploadResetRequested);
    on<UploadStatusRequested>(_onUploadStatusRequested);
    on<UploadPausedRequested>(_onUploadPausedRequested);
    on<UploadResumeRequested>(_onUploadResumeRequested);

    _statusSubscription = FlutterBackgroundService().on('update').listen((
      event,
    ) {
      add(UploadStatusRequested());
    });

    _completedSubscription = FlutterBackgroundService().on('completed').listen((
      event,
    ) {
      add(UploadStatusRequested());
    });
  }

  final UploadLocalDataSource _localDataSource;
  final _uuid = const Uuid();
  StreamSubscription<Map<String, dynamic>?>? _statusSubscription;
  StreamSubscription<Map<String, dynamic>?>? _completedSubscription;

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    _completedSubscription?.cancel();
    return super.close();
  }

  Future<void> _onUploadStatusRequested(
    UploadStatusRequested event,
    Emitter<UploadState> emit,
  ) async {
    final tasks = await _localDataSource.getAllTasks();
    if (tasks.isEmpty) {
      emit(UploadInitial());
    } else {
      emit(UploadInProgress(tasks: tasks));

      // Check if service needs to be started for pending tasks
      final hasPending = tasks.any((t) => t.status == UploadStatus.pending || t.status == UploadStatus.uploading);
      if (hasPending) {
        final service = FlutterBackgroundService();
        final isRunning = await service.isRunning();
        if (!isRunning) {
          await NotificationService.ensureChannelCreated();

          // Explicitly check for notification permission on Android 13+
          if (Platform.isAndroid) {
            final status = await Permission.notification.status;
            if (!status.isGranted) {
              await Permission.notification.request();
            }
          }

          await service.startService();
        }
      }
    }
  }

  void _onUploadPausedRequested(
    UploadPausedRequested event,
    Emitter<UploadState> emit,
  ) {
    FlutterBackgroundService().invoke('pause');
  }

  void _onUploadResumeRequested(
    UploadResumeRequested event,
    Emitter<UploadState> emit,
  ) {
    FlutterBackgroundService().invoke('resume');
  }

  Future<void> _onUploadStarted(
    UploadStarted event,
    Emitter<UploadState> emit,
  ) async {
    final newTasks = event.files
        .map(
          (file) => UploadTask(
            id: _uuid.v4(),
            file: file,
            status: UploadStatus.pending,
          ),
        )
        .toList();

    for (final task in newTasks) {
      await _localDataSource.addTask(task);
    }

    final allTasks = await _localDataSource.getAllTasks();
    emit(UploadInProgress(tasks: allTasks));

    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await NotificationService.ensureChannelCreated();

      // Explicitly check for notification permission on Android 13+
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          final result = await Permission.notification.request();
          if (!result.isGranted) {
            // Log or handle the case where permission is denied
            print(
              'UPLOAD_BLOC: Notification permission denied. Foreground service might fail.',
            );
          }
        }
      }

      await service.startService();
    }
  }

  void _onUploadTaskUpdated(
    UploadTaskUpdated event,
    Emitter<UploadState> emit,
  ) {
    if (state is UploadInProgress) {
      final tasks = List<UploadTask>.from((state as UploadInProgress).tasks);
      final index = tasks.indexWhere((t) => t.id == event.task.id);
      if (index != -1) {
        tasks[index] = event.task;
        emit(UploadInProgress(tasks: tasks));
      }
    }
  }

  Future<void> _onUploadResetRequested(
    UploadResetRequested event,
    Emitter<UploadState> emit,
  ) async {
    await _localDataSource.deleteAllTasks();
    FlutterBackgroundService().invoke('stopService');
    emit(UploadInitial());
  }
}
