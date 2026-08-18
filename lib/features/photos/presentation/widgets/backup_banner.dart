import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/screens/backup_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class BackupBanner extends StatelessWidget {
  const BackupBanner({
    required this.state,
    super.key,
  });

  final DeviceGalleryLoadSuccess state;

  @override
  Widget build(BuildContext context) {
    if (state.isAutoBackupEnabled && state.notBackedUpCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BackupSettingsScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  state.isAutoBackupEnabled ? Icons.cloud_done : Icons.error,
                  color: state.isAutoBackupEnabled ? AppColors.primary : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.isAutoBackupEnabled ? 'Backup is on' : 'Backup is off',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        state.notBackedUpCount > 0
                            ? '${state.notBackedUpCount} items not backed up'
                            : 'All photos backed up',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            if (state.notBackedUpCount > 0) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.notBackedUpThumbnails.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final asset = state.notBackedUpThumbnails[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: AssetEntityImage(
                          asset,
                          isOriginal: false,
                          thumbnailSize: const ThumbnailSize.square(200),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
