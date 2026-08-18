import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/core/theme/app_spacing.dart';
import 'package:arvan_photos/features/cloud/domain/entities/cloud_photo.dart';
import 'package:arvan_photos/features/cloud/presentation/bloc/cloud_bloc.dart';
import 'package:arvan_photos/features/cloud/presentation/bloc/cloud_event.dart';
import 'package:arvan_photos/features/cloud/presentation/bloc/cloud_state.dart';
import 'package:arvan_photos/features/cloud/presentation/screens/cloud_photo_detail_screen.dart';
import 'package:arvan_photos/features/cloud/presentation/widgets/cloud_photo_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CloudPhotosScreen extends StatefulWidget {
  const CloudPhotosScreen({super.key});

  @override
  State<CloudPhotosScreen> createState() => _CloudPhotosScreenState();
}

class _CloudPhotosScreenState extends State<CloudPhotosScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CloudBloc>().add(CloudPhotosRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Storage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CloudBloc>().add(CloudPhotosRequested()),
          ),
        ],
      ),
      body: BlocBuilder<CloudBloc, CloudState>(
        builder: (context, state) {
          if (state is CloudLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CloudLoadSuccess) {
            if (state.photos.isEmpty) {
              return _buildEmptyState();
            }
            return _buildPhotoGrid(state.photos);
          } else if (state is CloudLoadFailure) {
            return _buildErrorState(state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: AppSpacing.m),
          const Text('No photos in cloud storage'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.m),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.m),
            ElevatedButton(
              onPressed: () => context.read<CloudBloc>().add(CloudPhotosRequested()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(List<CloudPhoto> photos) {
    // Group photos by date
    final groupedPhotos = <String, List<CloudPhoto>>{};
    for (final photo in photos) {
      final dateKey = DateFormat('yyyy-MM-dd').format(photo.lastModified);
      groupedPhotos.putIfAbsent(dateKey, () => []).add(photo);
    }

    final sortedDates = groupedPhotos.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CloudBloc>().add(CloudPhotosRequested());
      },
      child: CustomScrollView(
        slivers: [
          ...sortedDates.expand((date) {
            final datePhotos = groupedPhotos[date]!;
            final displayDate = _getDisplayDate(date);

            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Text(
                    displayDate,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.s,
                    mainAxisSpacing: AppSpacing.s,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return CloudPhotoGridItem(
                        photo: datePhotos[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CloudPhotoDetailScreen(
                                photos: photos,
                                initialIndex: photos.indexOf(datePhotos[index]),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: datePhotos.length,
                  ),
                ),
              ),
            ];
          }).toList(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _getDisplayDate(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }
}
