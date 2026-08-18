import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class BackupSettingsScreen extends StatelessWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceGalleryBloc, DeviceGalleryState>(
      builder: (context, state) {
        if (state is! DeviceGalleryLoadSuccess) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAutoBackupEnabled = state.isAutoBackupEnabled;

        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    isAutoBackupEnabled ? 'Backup is on' : 'Backup is off',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ListTile(
                  title: const Text('Back up photos & videos on this device automatically'),
                  trailing: Switch(
                    value: isAutoBackupEnabled,
                    onChanged: (value) {
                      context
                          .read<DeviceGalleryBloc>()
                          .add(DeviceGalleryAutoBackupToggled(value));
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Backup account'),
                  subtitle: const Text('arvan_photos_user@example.com'),
                  enabled: isAutoBackupEnabled,
                ),
                ListTile(
                  title: const Text('Quality'),
                  trailing: const Text('Original', style: TextStyle(color: Colors.grey)),
                  subtitle: const Text('Full resolution'),
                  enabled: isAutoBackupEnabled,
                ),
                const Divider(),
                if (!isAutoBackupEnabled && state.notBackedUpCount > 0) ...[
                  _buildBackupStatusSection(context, state),
                ],
                const SizedBox(height: 24),
                _buildInfoCard(
                  context,
                  Icons.cloud_done_outlined,
                  'The photos and videos you back up are kept safe and secure. Learn more',
                ),
                _buildInfoCard(
                  context,
                  Icons.help_outline,
                  "Can't find your photo or video?",
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackupStatusSection(BuildContext context, DeviceGalleryLoadSuccess state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backup is off', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${state.notBackedUpCount} items not backed up'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.notBackedUpThumbnails.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == state.notBackedUpThumbnails.length) {
                  return _buildArrowButton(context);
                }
                final asset = state.notBackedUpThumbnails[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
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
      ),
    );
  }

  Widget _buildArrowButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        // In real app, we might enter selection mode or scroll to top
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.grey200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.arrow_forward, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
