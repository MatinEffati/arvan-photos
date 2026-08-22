import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/features/photos/domain/entities/device_asset.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/upload/upload_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/widgets/upload_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class LocalPhotoGridItem extends StatelessWidget {
  const LocalPhotoGridItem({required this.asset, required this.onTap, required this.onLongPress, super.key});

  final DeviceAsset asset;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BlocSelector<DeviceGalleryBloc, DeviceGalleryState, bool>(
        selector: (state) {
          if (state is DeviceGalleryLoadSuccess) {
            return state.selectedAssetIds.contains(asset.id);
          }
          return false;
        },
        builder: (context, isSelected) {
          return BlocSelector<DeviceGalleryBloc, DeviceGalleryState, bool>(
            selector: (state) {
              if (state is DeviceGalleryLoadSuccess) {
                return state.selectedAssetIds.isNotEmpty;
              }
              return false;
            },
            builder: (context, isSelectionMode) {
              return GestureDetector(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(isSelected ? 8 : 0),
                        child: ClipRRect(
                          // Google Photos packs grid thumbnails edge-to-edge with
                          // no rounding; a radius only appears once a photo is
                          // selected and shrinks inward.
                          borderRadius: BorderRadius.circular(isSelected ? 12 : 0),
                          child: AssetEntityImage(
                            AssetEntity(
                              id: asset.id,
                              typeInt: AssetType.image.index,
                              width: asset.width ?? 0,
                              height: asset.height ?? 0,
                              duration: asset.duration?.inSeconds ?? 0,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    if (isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                    if (isSelectionMode)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: isSelected
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    color: AppColors.white,
                                    size: 20,
                                  ),
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  const Icon(
                                    Icons.check,
                                    color: AppColors.white,
                                    size: 16,
                                  ),
                                ],
                              )
                            : Icon(
                                Icons.radio_button_unchecked,
                                color: AppColors.white.withValues(alpha: 0.6),
                                size: 24,
                                shadows: [
                                  Shadow(
                                    color: AppColors.black.withValues(alpha: 0.45),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                      ),

                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: BlocSelector<DeviceGalleryBloc, DeviceGalleryState, bool>(
                        selector: (state) {
                          if (state is DeviceGalleryLoadSuccess) {
                            return state.backedUpAssetIds.contains(asset.id);
                          }
                          return false;
                        },
                        builder: (context, isBackedUp) {
                          return BlocSelector<UploadBloc, UploadState, double?>(
                            selector: (state) => state.progressMap[asset.id],
                            builder: (context, progress) {
                              return UploadStatusBadge(isBackedUp: isBackedUp, progress: progress);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
