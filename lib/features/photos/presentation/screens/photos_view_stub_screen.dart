import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PhotosViewStubScreen extends StatefulWidget {
  const PhotosViewStubScreen({super.key});

  @override
  State<PhotosViewStubScreen> createState() => _PhotosViewStubScreenState();
}

class _PhotosViewStubScreenState extends State<PhotosViewStubScreen> {
  String _selectedLayout = 'Day';
  bool _stackSimilar = true;
  bool _showDates = true;
  bool _showShimmer = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Photos view'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Layout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Comfortable', label: Text('Comfortable')),
                  ButtonSegment(value: 'Day', label: Text('Day')),
                  ButtonSegment(value: 'Month', label: Text('Month')),
                ],
                selected: {_selectedLayout},
                onSelectionChanged: (value) {
                  setState(() => _selectedLayout = value.first);
                  if (_selectedLayout != 'Day') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Only Day layout is supported in this version')),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Stack similar photos'),
            subtitle: const Text('AI-powered grouping'),
            value: _stackSimilar,
            onChanged: (value) => setState(() => _stackSimilar = value),
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Show dates in grid'),
            value: _showDates,
            onChanged: (value) => setState(() => _showDates = value),
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Show shimmer'),
            subtitle: const Text('Loading placeholder animation'),
            value: _showShimmer,
            onChanged: (value) => setState(() => _showShimmer = value),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
