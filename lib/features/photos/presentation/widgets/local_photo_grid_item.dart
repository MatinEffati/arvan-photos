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
    this.backupStatus,
    super.key,
  });

  final AssetEntity asset;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelected;
  final bool isSelectionMode;
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
                child: Image(
                  image: AssetEntityImageProvider(asset, isOriginal: false, thumbnailSize: const ThumbnailSize.square(200)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // Selection Overlay
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

          // Selection Checkbox
          if (isSelectionMode)
            Positioned(
              top: 4,
              left: 4,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppColors.primary : Colors.white70,
                size: 24,
              ),
            ),

          // Backup Status Overlay
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
    switch (status) {
      case 'uploading':
        return Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
                value: null, // Indeterminate or use progress
              ),
            ),
            if (progress > 0)
              Text(
                '${(progress * 100).toInt()}',
                style: const TextStyle(color: Colors.white, fontSize: 8),
              ),
          ],
        );
      case 'synced':
        return const Icon(
          Icons.cloud_done,
          color: Colors.white,
          size: 20,
        );
      case 'failed':
        return const Icon(
          Icons.error,
          color: Colors.red,
          size: 20,
        );
      case 'queued':
        return const Icon(
          Icons.cloud_upload_outlined,
          color: Colors.white70,
          size: 20,
        );
      default:
        // Not backed up yet - show subtle icon or nothing like Google Photos
        return const Icon(
          Icons.cloud_off,
          color: Colors.white54,
          size: 18,
        );
    }
  }
}
