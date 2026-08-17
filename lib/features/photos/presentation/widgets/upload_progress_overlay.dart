import 'package:arvan_photos/core/theme/app_spacing.dart';
import 'package:arvan_photos/features/photos/domain/entities/upload_task.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/upload/upload_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UploadProgressOverlay extends StatelessWidget {
  const UploadProgressOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UploadBloc, UploadState>(
      builder: (context, state) {
        if (state is UploadInProgress) {
          final tasks = state.tasks;
          final overallProgress = state.overallProgress;
          final completed = state.completedCount;
          final total = state.totalCount;

          return Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          'Uploading $completed / $total photos...',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text('${(overallProgress * 100).toInt()}%'),
                      const SizedBox(width: AppSpacing.s),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          context.read<UploadBloc>().add(UploadResetRequested());
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  LinearProgressIndicator(value: overallProgress),
                  const SizedBox(height: AppSpacing.s),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _UploadTaskItem(task: task);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _UploadTaskItem extends StatelessWidget {
  const _UploadTaskItem({required this.task});

  final UploadTask task;

  @override
  Widget build(BuildContext context) {
    Color color;
    Widget icon;

    switch (task.status) {
      case UploadStatus.pending:
        color = Colors.grey;
        icon = const Icon(Icons.timer_outlined, size: 16, color: Colors.grey);
      case UploadStatus.uploading:
        color = Colors.blue;
        icon = SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            value: task.progress,
            strokeWidth: 2,
          ),
        );
      case UploadStatus.success:
        color = Colors.green;
        icon = const Icon(Icons.check_circle, size: 16, color: Colors.green);
      case UploadStatus.failure:
        color = Colors.red;
        icon = const Icon(Icons.error_outline, size: 16, color: Colors.red);
    }

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: AppSpacing.s),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  task.file,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  color: task.status == UploadStatus.pending ? Colors.black.withOpacity(0.5) : null,
                  colorBlendMode: task.status == UploadStatus.pending ? BlendMode.darken : null,
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: icon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            task.file.path.split('/').last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
