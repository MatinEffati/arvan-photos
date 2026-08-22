import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

const List<String> _kMonthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class LocalPhotoDetailScreen extends StatefulWidget {
  const LocalPhotoDetailScreen({
    required this.assets,
    required this.initialIndex,
    super.key,
  });

  final List<AssetEntity> assets;
  final int initialIndex;

  @override
  State<LocalPhotoDetailScreen> createState() => _LocalPhotoDetailScreenState();
}

class _LocalPhotoDetailScreenState extends State<LocalPhotoDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
  }

  String _formatDate(DateTime dt) {
    return '${_kMonthAbbr[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceGalleryBloc, DeviceGalleryState>(
      builder: (context, galleryState) {
        final currentAsset = widget.assets[_currentIndex];

        return Scaffold(
          backgroundColor: AppColors.white,
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: _chromeVisible ? AppColors.white : AppColors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: PhotoViewGallery.builder(
                    scrollPhysics: const BouncingScrollPhysics(),
                    builder: (context, index) {
                      return PhotoViewGalleryPageOptions(
                        imageProvider: AssetEntityImageProvider(
                          widget.assets[index],
                        ),
                        initialScale: PhotoViewComputedScale.contained,
                        minScale: PhotoViewComputedScale.contained * 1,
                        maxScale: PhotoViewComputedScale.covered * 4,
                        heroAttributes: PhotoViewHeroAttributes(
                          tag: widget.assets[index].id,
                        ),
                        onTapUp: (context, details, controllerValue) =>
                            _toggleChrome(),
                      );
                    },
                    itemCount: widget.assets.length,
                    loadingBuilder: (context, event) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    pageController: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: !_chromeVisible,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _chromeVisible ? 1 : 0,
                      child: SafeArea(
                        bottom: false,
                        child: _buildTopChrome(context, currentAsset),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: !_chromeVisible,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _chromeVisible ? 1 : 0,
                      child: SafeArea(
                        top: false,
                        child: _buildBottomChrome(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopChrome(BuildContext context, AssetEntity currentAsset) {
    final dt = currentAsset.createDateTime;

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDate(dt),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
                Text(
                  _formatTime(dt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.star_border, color: AppColors.textPrimary),
            onPressed: () {},
            tooltip: 'Favorite',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
            tooltip: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomChrome(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () => _showComingSoon(context, 'Share'),
          ),
          _ActionButton(
            icon: Icons.tune,
            label: 'Edit',
            onTap: () => _showComingSoon(context, 'Edit'),
          ),
          _ActionButton(
            icon: Icons.add,
            label: 'Add to',
            onTap: () => _showComingSoon(context, 'Add to'),
          ),
          _ActionButton(
            icon: Icons.delete_outline,
            label: 'Trash',
            onTap: () => _showComingSoon(context, 'Trash'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
