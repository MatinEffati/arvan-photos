import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/features/photos/domain/entities/photo_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PhotoGridItem extends StatelessWidget {
  const PhotoGridItem({
    required this.photo,
    required this.onTap,
    required this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.isDeleting = false,
    super.key,
  });

  final PhotoEntity photo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isSelected ? 10 : 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Opacity(
                  opacity: isDeleting ? 0.5 : 1.0,
                  child: CachedNetworkImage(
                    imageUrl: photo.url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ColoredBox(
                      color: AppColors.grey200,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const ColoredBox(
                      color: AppColors.grey200,
                      child: Icon(Icons.error_outline, color: AppColors.grey500),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isDeleting)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          if (isSelectionMode && !isDeleting)
            Positioned(
              top: 4,
              left: 4,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppColors.primary : Colors.white70,
                size: 24,
              ),
            ),
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
