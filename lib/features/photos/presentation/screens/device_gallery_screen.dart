import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_event.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_state.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/screens/backup_settings_screen.dart';
import 'package:arvan_photos/features/photos/presentation/screens/local_photo_detail_screen.dart';
import 'package:arvan_photos/features/photos/presentation/screens/photos_view_stub_screen.dart';
import 'package:arvan_photos/features/photos/presentation/widgets/date_section_header.dart';
import 'package:arvan_photos/features/photos/presentation/widgets/local_photo_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';

class DeviceGalleryScreen extends StatefulWidget {
  const DeviceGalleryScreen({super.key});

  @override
  State<DeviceGalleryScreen> createState() => _DeviceGalleryScreenState();
}

class _DeviceGalleryScreenState extends State<DeviceGalleryScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<DeviceGalleryBloc>().add(const DeviceGalleryRequested());
    context.read<BackupStatusBloc>().add(BackupStatusStarted());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh gallery when returning to app to catch any new downloads/changes
      context.read<DeviceGalleryBloc>().add(const DeviceGalleryRequested());
    }
  }

  void _confirmBulkDeleteCloud(BuildContext context, List<String> assetIds, BackupStatusState statusState) {
    final syncedIds = assetIds.where((id) => statusState.statuses[id]?.status == 'synced').toList();
    if (syncedIds.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete from Cloud'),
        content: Text('Are you sure you want to delete ${syncedIds.length} photos from ArvanCloud? Local files will remain.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DeviceGalleryBloc>().add(DeviceGalleryDeleteFromCloudRequested(syncedIds));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeviceGalleryBloc, DeviceGalleryState>(
      listener: (context, state) {
        if (state is DeviceGalleryBackupSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup tasks enqueued successfully')),
          );
        } else if (state is DeviceGalleryLoadFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        } else if (state is DeviceGalleryLoadSuccess && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.errorMessage}')),
          );
        }
      },
      builder: (context, state) {
        final isSelectionMode =
            state is DeviceGalleryLoadSuccess && state.selectedAssetIds.isNotEmpty;

        return Scaffold(
          appBar: _buildAppBar(context, state, isSelectionMode),
          body: _buildContent(state),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, DeviceGalleryState state, bool isSelectionMode) {
    if (isSelectionMode && state is DeviceGalleryLoadSuccess) {
      return AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              context.read<DeviceGalleryBloc>().add(const DeviceGallerySelectAllToggled()),
        ),
        title: Text('${state.selectedAssetIds.length} selected'),
        actions: [
          if (state is DeviceGalleryActionInProgress)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            // If any selected item is synced, show delete from cloud
            BlocBuilder<BackupStatusBloc, BackupStatusState>(
              builder: (context, statusState) {
                final anySynced = state.selectedAssetIds.any((id) => statusState.statuses[id]?.status == 'synced');
                if (anySynced) {
                  return IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                    onPressed: () {
                      _confirmBulkDeleteCloud(context, state.selectedAssetIds.toList(), statusState);
                    },
                    tooltip: 'Delete selected from Cloud',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            TextButton(
              onPressed: () {
                context.read<DeviceGalleryBloc>().add(const DeviceGalleryBackupRequested());
              },
              child: const Text('Back Up', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      );
    }

    String statusText = 'Gallery';
    if (state is DeviceGalleryLoadSuccess) {
      if (state.isAutoBackupEnabled) {
        statusText = state.notBackedUpCount > 0 ? 'Backing up...' : 'Backed up';
      } else {
        statusText = 'Backup is off';
      }
    }

    return AppBar(
      title: GestureDetector(
        onTap: () {
          final galleryBloc = context.read<DeviceGalleryBloc>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: galleryBloc,
                child: const BackupSettingsScreen(),
              ),
            ),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  statusText,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.grid_view, color: AppColors.grey700),
          onPressed: () {
            final galleryBloc = context.read<DeviceGalleryBloc>();
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider.value(
                  value: galleryBloc,
                  child: const PhotosViewStubScreen(),
                ),
              ),
            );
          },
          tooltip: 'Photos view',
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            final galleryBloc = context.read<DeviceGalleryBloc>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: galleryBloc,
                  child: const BackupSettingsScreen(),
                ),
              ),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.grey200,
            child: Icon(Icons.person, size: 18, color: AppColors.grey700),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(DeviceGalleryState state) {
    if (state is DeviceGalleryLoadInProgress) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is DeviceGalleryLoadSuccess) {
      if (state.groups.isEmpty) {
        return const Center(child: Text('No photos found on device'));
      }

      return RefreshIndicator(
        onRefresh: () async {
          context.read<DeviceGalleryBloc>().add(const DeviceGalleryRequested());
        },
        child: CustomScrollView(
          controller: _scrollController,
          cacheExtent: 1000, // Pre-render items outside view for smoother scrolling
          slivers: [
            ...state.groups.expand((group) {
              final groupIds = group.assets.map((a) => a.id).toSet();
              final isGroupSelected =
                  groupIds.every((id) => state.selectedAssetIds.contains(id));

              return [
                SliverToBoxAdapter(
                  child: DateSectionHeader(
                    title: group.title,
                    isSelected: isGroupSelected,
                    isSelectionMode: state.selectedAssetIds.isNotEmpty,
                    onToggleSelection: () {
                      context
                          .read<DeviceGalleryBloc>()
                          .add(DeviceGalleryGroupSelectionToggled(group.title));
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: state.gridColumns,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final asset = group.assets[index];
                        final isDeleting = state.deletingAssetIds.contains(asset.id);

                        return LocalPhotoGridItem(
                          key: ValueKey(asset.id),
                          asset: asset,
                          isDeleting: isDeleting,
                          onTap: () {
                            if (isDeleting) return;
                            if (state.selectedAssetIds.isNotEmpty) {
                              context
                                  .read<DeviceGalleryBloc>()
                                  .add(DeviceGallerySelectionToggled(asset.id));
                            } else {
                              final allAssets = state.groups.expand((g) => g.assets).toList();
                              final galleryBloc = context.read<DeviceGalleryBloc>();
                              final statusBloc = context.read<BackupStatusBloc>();

                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => MultiBlocProvider(
                                    providers: [
                                      BlocProvider.value(value: galleryBloc),
                                      BlocProvider.value(value: statusBloc),
                                    ],
                                    child: LocalPhotoDetailScreen(
                                      assets: allAssets.map((a) => AssetEntity(
                                        id: a.id,
                                        typeInt: AssetType.image.index,
                                        width: a.width ?? 0,
                                        height: a.height ?? 0,
                                        duration: a.duration?.inSeconds ?? 0,
                                      )).toList(),
                                      initialIndex: allAssets.indexOf(asset),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          onLongPress: () {
                            context
                                .read<DeviceGalleryBloc>()
                                .add(DeviceGallerySelectionToggled(asset.id));
                          },
                        );
                      },
                      childCount: group.assets.length,
                    ),
                  ),
                ),
              ];
            }),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
