import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_event.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_state.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/widgets/backup_action_bar.dart';
import 'package:arvan_photos/features/photos/presentation/widgets/date_section_header.dart';
import 'package:arvan_photos/features/photos/presentation/widgets/local_photo_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeviceGalleryScreen extends StatefulWidget {
  const DeviceGalleryScreen({super.key});

  @override
  State<DeviceGalleryScreen> createState() => _DeviceGalleryScreenState();
}

class _DeviceGalleryScreenState extends State<DeviceGalleryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DeviceGalleryBloc>().add(DeviceGalleryRequested());
    context.read<BackupStatusBloc>().add(BackupStatusStarted());
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
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gallery'),
            actions: [
              if (state is DeviceGalleryLoadSuccess)
                TextButton(
                  onPressed: () {
                    context.read<DeviceGalleryBloc>().add(DeviceGallerySelectAllToggled());
                  },
                  child: Text(
                    state.selectedAssetIds.isEmpty ? 'Select All' : 'Deselect All',
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              _buildContent(state),
              if (state is DeviceGalleryLoadSuccess && state.selectedAssetIds.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: BackupActionBar(
                    selectedCount: state.selectedAssetIds.length,
                    onBackupPressed: () {
                      context.read<DeviceGalleryBloc>().add(DeviceGalleryBackupRequested());
                    },
                    onClearSelection: () {
                      context.read<DeviceGalleryBloc>().add(DeviceGallerySelectAllToggled());
                    },
                  ),
                ),
            ],
          ),
        );
      },
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
          context.read<DeviceGalleryBloc>().add(DeviceGalleryRequested());
        },
        child: BlocBuilder<BackupStatusBloc, BackupStatusState>(
          builder: (context, statusState) {
            return CustomScrollView(
              slivers: state.groups.expand((group) {
                final groupIds = group.assets.map((a) => a.id).toSet();
                final isGroupSelected = groupIds.every((id) => state.selectedAssetIds.contains(id));

                return [
                  SliverToBoxAdapter(
                    child: DateSectionHeader(
                      title: group.title,
                      isSelected: isGroupSelected,
                      onToggleSelection: () {
                        context.read<DeviceGalleryBloc>().add(DeviceGalleryGroupSelectionToggled(group.title));
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final asset = group.assets[index];
                          return LocalPhotoGridItem(
                            asset: asset,
                            isSelected: state.selectedAssetIds.contains(asset.id),
                            isSelectionMode: state.selectedAssetIds.isNotEmpty,
                            backupStatus: statusState.statuses[asset.id],
                            onTap: () {
                              if (state.selectedAssetIds.isNotEmpty) {
                                context.read<DeviceGalleryBloc>().add(DeviceGallerySelectionToggled(asset.id));
                              } else {
                                // Full screen view not requested but could be added here
                              }
                            },
                            onLongPress: () {
                              context.read<DeviceGalleryBloc>().add(DeviceGallerySelectionToggled(asset.id));
                            },
                          );
                        },
                        childCount: group.assets.length,
                      ),
                    ),
                  ),
                ];
              }).toList(),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
