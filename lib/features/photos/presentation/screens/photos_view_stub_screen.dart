import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/core/theme/app_spacing.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
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
          appBar: AppBar(
            title: const Text('View Options'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Grid Layout'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
                  child: SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      selectedForegroundColor: AppColors.primary,
                    ),
                    segments: const [
                      ButtonSegment(value: 'Comfortable', label: Text('Comfortable')),
                      ButtonSegment(value: 'Day', label: Text('Day')),
                      ButtonSegment(value: 'Month', label: Text('Month')),
                    ],
                    selected: {currentLayout},
                    onSelectionChanged: (value) {
                      final selectedLayout = value.first;
                      final columns = _layoutToColumns(selectedLayout);
                      context.read<DeviceGalleryBloc>().add(DeviceGalleryGridColumnsChanged(columns));
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                _buildSectionHeader('Smart Features'),
            SwitchListTile(
              title: const Text('Group similar photos'),
              subtitle: const Text('Use AI to stack bursts and duplicates'),
              value: _stackSimilar,
              onChanged: (value) => setState(() => _stackSimilar = value),
              activeColor: AppColors.primary,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            ),
            const Divider(height: 1, indent: AppSpacing.l, color: AppColors.grey200),
            SwitchListTile(
              title: const Text('Show timeline dates'),
              subtitle: const Text('Display date headers in the photo grid'),
              value: _showDates,
              onChanged: (value) => setState(() => _showDates = value),
              activeColor: AppColors.primary,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            ),
            const SizedBox(height: AppSpacing.m),
            _buildSectionHeader('Appearance'),
            SwitchListTile(
              title: const Text('Loading Shimmer'),
              subtitle: const Text('Show animated placeholders while loading'),
              value: _showShimmer,
              onChanged: (value) => setState(() => _showShimmer = value),
              activeColor: AppColors.primary,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'Changes are applied immediately',
                style: TextStyle(color: AppColors.grey500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  },
);
}

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.l, AppSpacing.l, AppSpacing.s),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
