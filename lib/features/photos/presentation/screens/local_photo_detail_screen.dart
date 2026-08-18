import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_state.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class LocalPhotoDetailScreen extends StatefulWidget {
  const LocalPhotoDetailScreen({
    required this.assets,
    required this.initialIndex,
    super.key,
  });

  final List<AssetEntity> assets;
  final int initialIndex;

  @override
  State<LocalPhotoDetailScreen> createState() => _LocalPhotoDetailScreenState();
}

class _LocalPhotoDetailScreenState extends State<LocalPhotoDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _confirmDeleteCloud(BuildContext context, String assetId) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete from Cloud'),
        content: const Text('Are you sure you want to delete this photo from ArvanCloud? The local file will remain on your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DeviceGalleryBloc>().add(DeviceGalleryDeleteFromCloudRequested([assetId]));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeviceGalleryBloc, DeviceGalleryState>(
      listener: (context, state) {
        if (state is DeviceGalleryRequested && _currentIndex < widget.assets.length) {
          // Check if current item was deleted successfully (by checking if it's still in deleting list)
          // Actually the Silent refresh will handle status update via BackupStatusBloc.
        }
      },
      builder: (context, galleryState) {
        return BlocBuilder<BackupStatusBloc, BackupStatusState>(
          builder: (context, statusState) {
            final currentAsset = widget.assets[_currentIndex];
            final status = statusState.statuses[currentAsset.id]?['status'] as String?;
            final isDeleting = galleryState is DeviceGalleryLoadSuccess && galleryState.deletingAssetIds.contains(currentAsset.id);

            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  if (isDeleting || status == 'uploading')
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  else if (status == 'synced')
                    IconButton(
                      icon: const Icon(Icons.cloud_done, color: Colors.blue),
                      onPressed: () => _confirmDeleteCloud(context, currentAsset.id),
                      tooltip: 'Delete from Cloud',
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white70),
                      onPressed: () {
                        context.read<DeviceGalleryBloc>().add(DeviceGallerySelectionToggled(currentAsset.id));
                        context.read<DeviceGalleryBloc>().add(const DeviceGalleryBackupRequested());
                      },
                      tooltip: 'Back Up Now',
                    ),
                ],
              ),
              body: PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                builder: (context, index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: AssetEntityImageProvider(widget.assets[index], isOriginal: true),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained * 1,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    heroAttributes: PhotoViewHeroAttributes(tag: widget.assets[index].id),
                  );
                },
                itemCount: widget.assets.length,
                loadingBuilder: (context, event) => const Center(
                  child: CircularProgressIndicator(),
                ),
                pageController: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }
}
