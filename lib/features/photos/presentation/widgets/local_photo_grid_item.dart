import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class LocalPhotoGridItem extends StatelessWidget {
  const LocalPhotoGridItem({
    required this.asset,
    required this.onTap,
    required this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.isDeleting = false,
    this.backupStatus,
    super.key,
  });

  final AssetEntity asset;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isDeleting;
  final Map<String, dynamic>? backupStatus;

  @override
  Widget build(BuildContext context) {
    final status = backupStatus?['status'] as String?;
    final progress = (backupStatus?['progress'] as num?)?.toDouble() ?? 0.0;

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
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                  ],
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? AppColors.primary : Colors.white,
                  size: 24,
                ),
              ),
            ),

          if (!isDeleting)
            Positioned(
              bottom: 4,
              right: 4,
              child: _buildStatusIcon(status, progress),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String? status, double progress) {
    Widget icon;
    switch (status) {
      case 'uploading':
        icon = Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
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
                ),
              ),
          ],
        );
        break;
      case 'synced':
        icon = const Icon(
          Icons.cloud_done,
          color: Colors.white,
          size: 20,
        );
        break;
      case 'failed':
        icon = const Icon(
          Icons.error,
          color: AppColors.error,
          size: 20,
        );
        break;
      case 'queued':
        icon = const Icon(
          Icons.cloud_upload,
          color: Colors.white,
          size: 20,
        );
        break;
      default:
        // By default show cloud_off for items not synced/queued
        icon = const Icon(
          Icons.cloud_off,
          color: Colors.white70,
          size: 18,
        );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black26,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: icon,
    );
  }
}
