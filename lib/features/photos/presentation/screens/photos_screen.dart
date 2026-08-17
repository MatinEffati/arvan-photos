import 'dart:io';
import 'package:arvan_photos/core/theme/app_spacing.dart';
import 'package:arvan_photos/core/theme/app_text_styles.dart';
import 'package:arvan_photos/features/photos/domain/entities/sort_option.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/photos/photos_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/upload/upload_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/screens/photo_detail_screen.dart';
import 'package:arvan_photos/features/photos/presentation/widgets/photo_grid_item.dart';
import 'package:arvan_photos/features/photos/presentation/widgets/photo_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final _imagePicker = ImagePicker();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<PhotosBloc>().add(const PhotosRequested());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      context.read<PhotosBloc>().add(PhotosLoadMoreRequested());
    }
  }

  Future<void> _pickAndUploadImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      if (mounted) {
        context.read<UploadBloc>().add(UploadStarted(pickedFiles.map((f) => File(f.path)).toList()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UploadBloc, UploadState>(
          listener: (context, state) {
            if (state is UploadSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All uploads successful')),
              );
              context.read<PhotosBloc>().add(const PhotosRequested(isRefresh: true));
            } else if (state is UploadFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Upload failed: ${state.message}')),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<PhotosBloc, PhotosState>(
        builder: (context, photosState) {
          final isSelectionMode = photosState.isSelectionMode;

          return Scaffold(
            appBar: AppBar(
              leading: isSelectionMode
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.read<PhotosBloc>().add(PhotosSelectionCleared()),
                    )
                  : null,
              title: Text(
                isSelectionMode ? '${photosState.selectedPhotoKeys.length} selected' : 'Photos',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                if (isSelectionMode)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      _confirmBulkDelete(context);
                    },
                  )
                else
                  PopupMenuButton<SortOption>(
                    icon: const Icon(Icons.sort),
                    onSelected: (option) {
                      context.read<PhotosBloc>().add(PhotosSortChanged(option));
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: SortOption.dateDescending,
                        child: Text('Newest first'),
                      ),
                      const PopupMenuItem(
                        value: SortOption.dateAscending,
                        child: Text('Oldest first'),
                      ),
                      const PopupMenuItem(
                        value: SortOption.nameAscending,
                        child: Text('Name (A-Z)'),
                      ),
                      const PopupMenuItem(
                        value: SortOption.sizeDescending,
                        child: Text('Size (Largest)'),
                      ),
                    ],
                  ),
              ],
            ),
            body: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<PhotosBloc>().add(const PhotosRequested(isRefresh: true));
                  },
                  child: _buildContent(photosState),
                ),
                _buildUploadOverlay(),
              ],
            ),
            floatingActionButton: isSelectionMode
                ? null
                : FloatingActionButton.extended(
                    onPressed: _pickAndUploadImages,
                    label: const Text('Upload'),
                    icon: const Icon(Icons.add_a_photo),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildContent(PhotosState state) {
    if (state is PhotosLoadInProgress) {
      return const PhotoShimmer();
    } else if (state is PhotosLoadSuccess) {
      if (state.photos.isEmpty) {
        return const Center(child: Text('No photos yet'));
      }
      return CustomScrollView(
        controller: _scrollController,
        slivers: [
          ...state.groupedPhotos.expand((group) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, AppSpacing.s),
                    child: Text(
                      _formatDate(group.date),
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final photo = group.photos[index];
                        final isSelected = state.selectedPhotoKeys.contains(photo.key);
                        return PhotoGridItem(
                          key: ValueKey(photo.key),
                          photo: photo,
                          isSelected: isSelected,
                          isSelectionMode: state.isSelectionMode,
                          onTap: () {
                            if (state.isSelectionMode) {
                              context.read<PhotosBloc>().add(PhotoSelectionToggled(photo.key));
                            } else {
                              Navigator.push<bool>(
                                context,
                                MaterialPageRoute<bool>(
                                  builder: (_) => PhotoDetailScreen(
                                    photos: state.photos,
                                    initialIndex: state.photos.indexOf(photo),
                                  ),
                                ),
                              ).then((value) {
                                if (value == true && mounted) {
                                  context.read<PhotosBloc>().add(const PhotosRequested(isRefresh: true));
                                }
                              });
                            }
                          },
                          onLongPress: () {
                            context.read<PhotosBloc>().add(PhotoSelectionToggled(photo.key));
                          },
                        );
                      },
                      childCount: group.photos.length,
                    ),
                  ),
                ),
              ]),
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      );
    } else if (state is PhotosLoadFailure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.message}'),
            ElevatedButton(
              onPressed: () {
                context.read<PhotosBloc>().add(const PhotosRequested());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildUploadOverlay() {
    return BlocBuilder<UploadBloc, UploadState>(
      builder: (context, state) {
        if (state is UploadInProgress) {
          return Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Text(
                            'Uploading ${state.currentFileIndex + 1} of ${state.totalFiles}...',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text('${(state.progress * 100).toInt()}%'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    LinearProgressIndicator(value: state.progress),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _confirmBulkDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Photos'),
        content: Text('Are you sure you want to delete ${context.read<PhotosBloc>().state.selectedPhotoKeys.length} photos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<PhotosBloc>().add(MultiplePhotosDeleteRequested());
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final photoDate = DateTime(date.year, date.month, date.day);

    if (photoDate == today) return 'Today';
    if (photoDate == yesterday) return 'Yesterday';
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }
}
