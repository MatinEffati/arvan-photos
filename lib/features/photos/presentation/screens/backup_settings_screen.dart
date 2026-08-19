import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/core/theme/app_spacing.dart';
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
            title: const Text('Backup Settings'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isAutoBackupEnabled),
                _buildToggleSection(context, isAutoBackupEnabled),
                const Divider(height: 1, color: AppColors.grey200),
                _buildAccountSection(isAutoBackupEnabled),
                _buildQualitySection(isAutoBackupEnabled),
                const Divider(height: 1, color: AppColors.grey200),
                if (!isAutoBackupEnabled && state.notBackedUpCount > 0) ...[
                  _buildNotBackedUpSection(context, state),
                ],
                const SizedBox(height: AppSpacing.l),
                _buildSafetyInfo(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isAutoBackupEnabled) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.l, AppSpacing.l, AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAutoBackupEnabled ? 'Backup is active' : 'Backup is disabled',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isAutoBackupEnabled ? AppColors.primary : AppColors.grey700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isAutoBackupEnabled 
                ? 'Your photos are being synced to ArvanCloud' 
                : 'Turn on backup to keep your photos safe in the cloud',
            style: const TextStyle(color: AppColors.grey700),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSection(BuildContext context, bool isAutoBackupEnabled) {
    return SwitchListTile(
      title: const Text('Automatic Backup', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('Back up photos & videos from this device'),
      value: isAutoBackupEnabled,
      onChanged: (value) {
        context.read<DeviceGalleryBloc>().add(DeviceGalleryAutoBackupToggled(value));
      },
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
    );
  }

  Widget _buildAccountSection(bool isAutoBackupEnabled) {
    return ListTile(
      leading: const CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.grey200,
        child: Icon(Icons.person, color: AppColors.grey700, size: 20),
      ),
      title: const Text('Backup Account'),
      subtitle: const Text('arvan_photos_user@example.com'),
      enabled: isAutoBackupEnabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
    );
  }

  Widget _buildQualitySection(bool isAutoBackupEnabled) {
    return ListTile(
      leading: const Icon(Icons.high_quality_outlined, color: AppColors.grey700),
      title: const Text('Upload Quality'),
      subtitle: const Text('Original quality • Full resolution'),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey500),
      enabled: isAutoBackupEnabled,
      onTap: () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
    );
  }

  Widget _buildNotBackedUpSection(BuildContext context, DeviceGalleryLoadSuccess state) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_off_outlined, color: AppColors.error, size: 24),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Action required', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                    Text('${state.notBackedUpCount} items waiting to be backed up'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.notBackedUpThumbnails.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final asset = state.notBackedUpThumbnails[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: AssetEntityImage(
                      AssetEntity(
                        id: asset.id,
                        typeInt: AssetType.image.index,
                        width: asset.width ?? 0,
                        height: asset.height ?? 0,
                        duration: asset.duration?.inSeconds ?? 0,
                      ),
                      isOriginal: false,
                      thumbnailSize: const ThumbnailSize.square(150),
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

  Widget _buildSafetyInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Column(
        children: [
          _buildInfoItem(
            Icons.security_outlined,
            'The photos and videos you back up are private and encrypted in ArvanCloud storage.',
          ),
          const SizedBox(height: AppSpacing.m),
          _buildInfoItem(
            Icons.help_outline,
            'Need help? Visit the Arvan Photos Support Center.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.grey500, size: 20),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.grey700),
          ),
        ),
      ],
    );
  }
}
