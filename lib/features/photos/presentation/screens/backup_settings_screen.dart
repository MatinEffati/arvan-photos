import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/core/theme/app_spacing.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

/// Colors pulled directly from the reference screenshot (Material-You style
/// dynamic tan/amber theme, not the standard Google blue). Kept local to this
/// file since app_colors.dart doesn't define this specific palette.
class _RefColors {
  const _RefColors._();

  static const titleBlack = Color(0xFF212121);
  static const bodyGrey = Color(0xFF5F6368);
  static const disabledGrey = Color(0xFF9AA0A6);
  static const dividerGrey = Color(0xFFE0E0E0);

  static const tooltipBrown = Color(0xFF6B5022);
  static const alertRed = Color(0xFFC0574D);
  static const bannerBg = Color(0xFFF4F0ED);
  static const shieldBlue = Color(0xFF194D79);
  static const accentBrown = Color(0xFF6B5022);
  static const arrowChipBg = Color(0xFF3C4043);
}

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  bool _tooltipDismissed = false;

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
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _RefColors.titleBlack),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: _RefColors.titleBlack),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(isAutoBackupEnabled),
                _buildToggleRow(context, isAutoBackupEnabled),
                const SizedBox(height: AppSpacing.m),
                _buildAccountRow(isAutoBackupEnabled),
                _buildQualityRow(isAutoBackupEnabled),
                const Divider(height: 1, thickness: 1, color: _RefColors.dividerGrey),
                if (!isAutoBackupEnabled && state.notBackedUpCount > 0)
                  _buildNotBackedUpSection(context, state),
                const SizedBox(height: AppSpacing.l),
                _buildSafetyBanner(context),
                const SizedBox(height: AppSpacing.m),
                _buildHelpRow(),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(bool isAutoBackupEnabled) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, AppSpacing.l),
      child: Text(
        isAutoBackupEnabled ? 'Backup is on' : 'Backup is off',
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w400,
          color: _RefColors.titleBlack,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildToggleRow(BuildContext context, bool isAutoBackupEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Back up photos & videos on this device automatically',
                  style: TextStyle(
                    fontSize: 15,
                    color: _RefColors.titleBlack,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: isAutoBackupEnabled,
                  onChanged: (value) {
                    setState(() => _tooltipDismissed = true);
                    context.read<DeviceGalleryBloc>().add(DeviceGalleryAutoBackupToggled(value));
                  },
                  activeColor: Colors.white,
                  activeTrackColor: AppColors.primary,
                  inactiveThumbColor: _RefColors.titleBlack,
                  inactiveTrackColor: const Color(0xFFDCDCDC),
                ),
              ),
            ],
          ),
          if (!isAutoBackupEnabled && !_tooltipDismissed) ...[
            const SizedBox(height: AppSpacing.s),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => setState(() => _tooltipDismissed = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _RefColors.tooltipBrown,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Turn on automatic backup',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountRow(bool isAutoBackupEnabled) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      title: Text(
        'Backup account',
        style: TextStyle(
          fontSize: 15,
          color: isAutoBackupEnabled ? _RefColors.titleBlack : _RefColors.disabledGrey,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: _RefColors.disabledGrey.withValues(alpha: 0.6)),
      onTap: isAutoBackupEnabled ? () {} : null,
    );
  }

  Widget _buildQualityRow(bool isAutoBackupEnabled) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      title: Text(
        'Quality',
        style: TextStyle(
          fontSize: 15,
          color: isAutoBackupEnabled ? _RefColors.titleBlack : _RefColors.disabledGrey,
        ),
      ),
      trailing: Text(
        'Original',
        style: TextStyle(
          fontSize: 15,
          color: isAutoBackupEnabled ? _RefColors.bodyGrey : _RefColors.disabledGrey,
        ),
      ),
      onTap: isAutoBackupEnabled ? () {} : null,
    );
  }

  Widget _buildNotBackedUpSection(BuildContext context, DeviceGalleryLoadSuccess state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.l, AppSpacing.l, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: const BoxDecoration(
                  color: _RefColors.alertRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.priority_high, color: Colors.white, size: 16),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backup is off',
                      style: TextStyle(fontSize: 15, color: _RefColors.titleBlack),
                    ),
                    Text(
                      '${state.notBackedUpCount} items not backed up',
                      style: const TextStyle(fontSize: 13, color: _RefColors.bodyGrey),
                    ),
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
              itemCount: state.notBackedUpThumbnails.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == state.notBackedUpThumbnails.length) {
                  // "See all / continue" affordance, matches the dark
                  // rounded arrow chip at the end of the thumbnail strip.
                  return GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: _RefColors.arrowChipBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                      ),
                    ),
                  );
                }

                final asset = state.notBackedUpThumbnails[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
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

  Widget _buildSafetyBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: _RefColors.bannerBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined, color: _RefColors.shieldBlue, size: 22),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, color: _RefColors.titleBlack, height: 1.4),
                  children: [
                    const TextSpan(
                      text: 'The photos and videos you back up are kept safe and secure. ',
                    ),
                    TextSpan(
                      text: 'Learn more',
                      style: const TextStyle(
                        color: _RefColors.accentBrown,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.help_outline, color: _RefColors.titleBlack, size: 20),
              ),
              const SizedBox(width: AppSpacing.m),
              const Text(
                "Can't find your photo or video?",
                style: TextStyle(fontSize: 14, color: _RefColors.titleBlack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}