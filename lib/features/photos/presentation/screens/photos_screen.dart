import 'dart:io';
import 'package:arvan_photos/core/theme/app_spacing.dart';
import 'package:arvan_photos/features/photos/domain/entities/sort_option.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/photos/photos_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/upload/upload_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/screens/photo_detail_screen.dart';
import 'package:arvan_photos/features/photos/presentation/widgets/photo_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<PhotosBloc>().add(PhotosLoadMoreRequested());
    }
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (mounted) {
        context.read<UploadBloc>().add(UploadStarted(File(pickedFile.path)));
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
                const SnackBar(content: Text('Upload successful')),
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Photos'),
          actions: [
            BlocBuilder<PhotosBloc, PhotosState>(
              builder: (context, state) {
                return PopupMenuButton<SortOption>(
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
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<PhotosBloc>().add(const PhotosRequested(isRefresh: true));
          },
          child: BlocBuilder<PhotosBloc, PhotosState>(
            builder: (context, state) {
              if (state is PhotosLoadInProgress) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is PhotosLoadSuccess) {
                if (state.photos.isEmpty) {
                  return const Center(child: Text('No photos yet'));
                }
                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.s),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: AppSpacing.s,
                          mainAxisSpacing: AppSpacing.s,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final photo = state.photos[index];
                            return PhotoGridItem(
                              photo: photo,
                              onTap: () {
                                Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute<bool>(
                                    builder: (_) => PhotoDetailScreen(
                                      photos: state.photos,
                                      initialIndex: index,
                                    ),
                                  ),
                                ).then((value) {
                                  if (value == true && mounted) {
                                    context.read<PhotosBloc>().add(const PhotosRequested(isRefresh: true));
                                  }
                                });
                              },
                            );
                          },
                          childCount: state.photos.length,
                        ),
                      ),
                    ),
                    if (state.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    if (!state.hasMore && state.photos.isNotEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                          child: Center(
                            child: Text(
                              'No more photos',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
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
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _pickAndUploadImage,
          child: BlocBuilder<UploadBloc, UploadState>(
            builder: (context, state) {
              if (state is UploadInProgress) {
                return const CircularProgressIndicator(color: Colors.white);
              }
              return const Icon(Icons.add_a_photo);
            },
          ),
        ),
      ),
    );
  }
}
