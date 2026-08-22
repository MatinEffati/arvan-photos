import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This screen contains toggles for Layout, Shimmer, and Dates which are
/// intentionally non-functional per product decision (Scope 9.3 of gallery-backup-feature).
/// They are kept as stubs for future implementation and UI completeness.
class PhotosViewStubScreen extends StatefulWidget {
  const PhotosViewStubScreen({super.key});

  @override
  State<PhotosViewStubScreen> createState() => _PhotosViewStubScreenState();
}

class _PhotosViewStubScreenState extends State<PhotosViewStubScreen> {
  bool _stackSimilar = true;
  bool _showDates = true;
  bool _showShimmer = true;

  String _columnsToLayout(int columns) {
    if (columns == 2) return 'Comfortable';
    if (columns == 5) return 'Month';
    return 'Day';
  }

  int _layoutToColumns(String layout) {
    if (layout == 'Comfortable') return 2;
    if (layout == 'Month') return 5;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceGalleryBloc, DeviceGalleryState>(
      builder: (context, state) {
        final currentLayout = state is DeviceGalleryLoadSuccess
            ? _columnsToLayout(state.gridColumns)
            : 'Day';

        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            centerTitle: false,
            titleSpacing: 4,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: const Text(
              'Photos view',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildSectionLabel('Layout'),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _LayoutSegmentedControl(
                    selected: currentLayout,
                    onChanged: (layout) {
                      final columns = _layoutToColumns(layout);
                      context
                          .read<DeviceGalleryBloc>()
                          .add(DeviceGalleryGridColumnsChanged(columns));
                    },
                  ),
                ),
                const SizedBox(height: 28),
                _SwitchRow(
                  title: 'Stack similar photos',
                  subtitle:
                  'Automatically group similar photos that were taken together.',
                  linkText: 'Learn more',
                  value: _stackSimilar,
                  onChanged: (value) => setState(() => _stackSimilar = value),
                  onLinkTap: () {},
                ),
                const SizedBox(height: 20),
                _SwitchRow(
                  title: 'Show dates in grid',
                  value: _showDates,
                  onChanged: (value) => setState(() => _showDates = value),
                ),
                const SizedBox(height: 20),
                _SwitchRow(
                  title: 'Show shimmer',
                  subtitle:
                  'Outlines people or objects in your photos that you can take action on.',
                  linkText: 'Learn more',
                  value: _showShimmer,
                  onChanged: (value) => setState(() => _showShimmer = value),
                  onLinkTap: () {},
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1, color: AppColors.dividerLight),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.grey600,
        ),
      ),
    );
  }
}

/// Custom segmented control matching the reference design:
/// a soft peach rounded container with 3 columns (icon + label),
/// the selected column sits on a lighter card and its label sits
/// inside a solid dark pill.
class _LayoutSegmentedControl extends StatelessWidget {
  const _LayoutSegmentedControl({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const _items = <_LayoutItem>[
    _LayoutItem(label: 'Comfortable', icon: Icons.vertical_split_outlined),
    _LayoutItem(label: 'Day', icon: Icons.grid_view_rounded),
    _LayoutItem(label: 'Month', icon: Icons.grid_on_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: _items.map((item) {
          final isSelected = item.label == selected;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(item.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.white.withValues(alpha: 0.55) : AppColors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: AppColors.primary, size: 24),
                    const SizedBox(height: 10),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: AppColors.textBrown,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LayoutItem {
  const _LayoutItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Title + optional subtitle (with an inline underlined link) + a pill switch,
/// laid out with no divider between rows, matching the reference screenshot.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.linkText,
    this.onLinkTap,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final String? linkText;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.grey600,
                      ),
                      children: [
                        TextSpan(text: '$subtitle '),
                        if (linkText != null)
                          TextSpan(
                            text: linkText,
                            style: const TextStyle(
                              color: AppColors.grey600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: onLinkTap == null
                                ? null
                                : (TapGestureRecognizer()..onTap = onLinkTap),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _PillSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PillSwitch extends StatelessWidget {
  const _PillSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.white,
      activeTrackColor: AppColors.primary,
      inactiveThumbColor: AppColors.white,
      inactiveTrackColor: AppColors.divider,
      trackOutlineColor: const WidgetStatePropertyAll(AppColors.transparent),
      trackOutlineWidth: const WidgetStatePropertyAll(0),
    );
  }
}