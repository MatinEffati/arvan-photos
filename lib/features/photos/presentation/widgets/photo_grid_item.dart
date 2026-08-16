import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/features/photos/domain/entities/photo_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PhotoGridItem extends StatelessWidget {
  const PhotoGridItem({
    required this.photo,
    required this.onTap,
    super.key,
  });

  final PhotoEntity photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: photo.url,
          fit: BoxFit.cover,
          placeholder: (context, url) => const ColoredBox(
            color: AppColors.grey200,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => const ColoredBox(
            color: AppColors.grey200,
            child: Icon(Icons.error_outline, color: AppColors.grey500),
          ),
        ),
      ),
    );
  }
}
