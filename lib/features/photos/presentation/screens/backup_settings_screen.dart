import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/core/theme/app_spacing.dart';
import 'package:arvan_photos/features/photos/domain/entities/device_asset.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';


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
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
                onPressed: () {},
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(isAutoBackupEnabled),
                    _buildToggleRow(context, isAutoBackupEnabled),
                    const SizedBox(height: AppSpacing.m),
                    _buildAccountRow(isAutoBackupEnabled),
                    _buildQualityRow(isAutoBackupEnabled),
                    const Divider(height: 1, thickness: 1, color: AppColors.divider),
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
              // Floating tooltip overlaid on top of the content — it does
              // NOT take up layout space, so the rows below (Backup
              // account, Quality, ...) never shift or gain extra spacing
              // because of it.
              if (!isAutoBackupEnabled && !_tooltipDismissed)
                _buildFloatingTooltip(context),
            ],
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
          color: AppColors.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildToggleRow(BuildContext context, bool isAutoBackupEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Text(
              'Back up photos & videos on this device automatically',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
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
              activeThumbColor: AppColors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: AppColors.textPrimary,
              inactiveTrackColor: AppColors.inactiveTrack,
            ),
          ),
        ],
      ),
    );
  }

  /// Speech-bubble style floating tooltip, positioned as an overlay via
  /// [Positioned] so it does NOT participate in the column's layout flow.
  /// The rows below the toggle (Backup account, Quality, ...) keep their
  /// normal spacing regardless of whether this tooltip is shown.
  /// The top offset approximates the bottom-right of the toggle row —
  /// adjust it if the title/toggle styles above change.
  Widget _buildFloatingTooltip(BuildContext context) {
    return Positioned(
      top: 130,
      right: AppSpacing.l,
      child: GestureDetector(
        onTap: () => setState(() => _tooltipDismissed = true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tail pointing up toward the switch, offset in from the
            // right edge of the bubble below it.
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: CustomPaint(
                size: const Size(18, 8),
                painter: _TooltipTailPainter(color: AppColors.accentBrown),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentBrown,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Turn on automatic backup',
                style: TextStyle(color: AppColors.white, fontSize: 14),
              ),
            ),
          ],
        ),
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
          color: isAutoBackupEnabled ? AppColors.textPrimary : AppColors.grey500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'example@gmail.com',
            style: TextStyle(
              fontSize: 14,
              color: isAutoBackupEnabled ? AppColors.grey700 : AppColors.grey500,
            ),
          ),
        ],
      ),
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
          color: isAutoBackupEnabled ? AppColors.textPrimary : AppColors.grey500,
        ),
      ),
      trailing: Text(
        'Original',
        style: TextStyle(
          fontSize: 15,
          color: isAutoBackupEnabled ? AppColors.grey700 : AppColors.grey500,
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
            // Center the red badge between the title and subtitle lines
            // instead of pinning it to the top.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.priority_high, color: AppColors.white, size: 14),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backup is off',
                      style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${state.notBackedUpCount} items not backed up',
                      style: const TextStyle(fontSize: 13, color: AppColors.grey700),
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
                        color: AppColors.chipBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_forward, color: AppColors.white, size: 22),
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
          color: AppColors.bannerBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.shieldBlue, size: 22),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4,fontWeight: FontWeight.w500),
                  children: [
                    const TextSpan(
                      text: 'The photos and videos you back up are kept safe and secure. ',
                    ),
                    TextSpan(
                      text: 'Learn more',
                      style: const TextStyle(
                        color: AppColors.accentBrown,
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.bannerBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.help_outline, color: AppColors.textPrimary, size: 20),
              ),
              const SizedBox(width: AppSpacing.m),
              const Text(
                "Can't find your photo or video?",
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a small upward-pointing triangle used as the tooltip's tail,
/// connecting the speech-bubble banner to the toggle above it.
class _TooltipTailPainter extends CustomPainter {
  const _TooltipTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TooltipTailPainter oldDelegate) => oldDelegate.color != color;
}