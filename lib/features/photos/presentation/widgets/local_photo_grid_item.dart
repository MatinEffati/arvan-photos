import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_state.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class LocalPhotoGridItem extends StatelessWidget {
  const LocalPhotoGridItem({
    required this.asset,
    required this.onTap,
    required this.onLongPress,
    this.isDeleting = false,
    super.key,
  });

  final AssetEntity asset;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BlocSelector<DeviceGalleryBloc, DeviceGalleryState, bool>(
        selector: (state) {
          if (state is DeviceGalleryLoadSuccess) {
            return state.selectedAssetIds.contains(asset.id);
          }
          return false;
        },
        builder: (context, isSelected) {
          return BlocSelector<DeviceGalleryBloc, DeviceGalleryState, bool>(
            selector: (state) {
              if (state is DeviceGalleryLoadSuccess) {
                return state.selectedAssetIds.isNotEmpty;
              }
              return false;
            },
            builder: (context, isSelectionMode) {
              return GestureDetector(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(isSelected ? 8 : 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Opacity(
                            opacity: isDeleting ? 0.5 : 1.0,
                            child: AssetEntityImage(
                              asset,
                              isOriginal: false,
                              thumbnailSize: const ThumbnailSize.square(200),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    if (isDeleting)
                      const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      ),
          
                    if (isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
          
                    if (isSelectionMode && !isDeleting)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? AppColors.primary : Colors.white,
                          size: 24,
                          shadows: const [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
          
                    if (!isDeleting)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: BlocSelector<BackupStatusBloc, BackupStatusState, Map<String, dynamic>?>(
                          selector: (state) => state.statuses[asset.id],
                          builder: (context, statusInfo) {
                            final status = statusInfo?['status'] as String?;
                            final progress = (statusInfo?['progress'] as num?)?.toDouble() ?? 0.0;
                            return _buildStatusIcon(status, progress);
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(String? status, double progress) {
    const iconShadows = [
      Shadow(
        color: Colors.black45,
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ];

    switch (status) {
      case 'uploading':
        return Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            if (progress > 0)
              Text(
                '${(progress * 100).toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  shadows: iconShadows,
                ),
              ),
          ],
        );
      case 'synced':
        return const Icon(
          Icons.cloud_done,
          color: Colors.white,
          size: 18,
          shadows: iconShadows,
        );
      case 'failed':
        return const Icon(
          Icons.error_outline,
          color: AppColors.error,
          size: 18,
          shadows: iconShadows,
        );
      case 'queued':
        return const Icon(
          Icons.cloud_upload_outlined,
          color: Colors.white,
          size: 18,
          shadows: iconShadows,
        );
      default:
        // Minimalist: Don't show cloud_off by default to keep UI clean
        return const SizedBox.shrink();
    }
  }
}
