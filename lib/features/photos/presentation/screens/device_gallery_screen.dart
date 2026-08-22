import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/delete/delete_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/upload/upload_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/screens/backup_settings_screen.dart';
import 'package:arvan_photos/features/photos/presentation/screens/local_photo_detail_screen.dart';
import 'package:arvan_photos/features/photos/presentation/screens/photos_view_stub_screen.dart';
import 'package:arvan_photos/features/photos/presentation/widgets/local_photo_grid_item.dart';
import 'package:arvan_photos/features/photos/presentation/widgets/trash_confirmation_dialog.dart';
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

  // Drives the collapsing toolbar <-> floating pill crossfade. 0 = toolbar
  // fully shown (top of list), 1 = toolbar hidden / pill+scrim fully shown.
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0);

  // Which date group is currently at the top of the viewport — this is what
  // the floating pill displays. Recomputed from real scroll offsets, not
  // tied to any single group's own header (there isn't one anymore).
  final ValueNotifier<String> _currentGroupTitle = ValueNotifier('');

  // Cumulative pixel offset where each group starts, rebuilt whenever the
  // groups or column count change. Used purely for the scroll -> title
  // lookup above.
  List<double> _groupStartOffsets = [];
  List<String> _groupTitles = [];

  // Asset ids from the most recent trash confirmation, still waiting on
  // DeleteSuccess/DeleteFailure. Drives the non-dismissible delete overlay:
  // it stays up until every id in this set has resolved.
  final Set<String> _pendingDeleteIds = {};
  bool _deleteOverlayShown = false;

  static const double _kCollapseStart = 10;
  static const double _kCollapseEnd = 70;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<DeviceGalleryBloc>().add(const DeviceGalleryRequested());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _scrollProgress.dispose();
    _currentGroupTitle.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh gallery when returning to app to catch any new downloads/changes
      context.read<DeviceGalleryBloc>().add(const DeviceGalleryRequested());
    }
  }

  void _onScroll() {
    final offset = _scrollController.offset;

    final progress = ((offset - _kCollapseStart) / (_kCollapseEnd - _kCollapseStart)).clamp(0.0, 1.0);
    if (progress != _scrollProgress.value) {
      _scrollProgress.value = progress;
    }

    if (_groupStartOffsets.isEmpty) return;
    var index = 0;
    for (var i = 0; i < _groupStartOffsets.length; i++) {
      if (offset >= _groupStartOffsets[i]) index = i;
    }
    final title = _groupTitles[index];
    if (title != _currentGroupTitle.value) {
      _currentGroupTitle.value = title;
    }
  }

  /// Precomputes where each date group starts in the scroll view so we can
  /// map "current scroll offset" -> "current group title" for the floating
  /// pill. Square grid items, same math the SliverGrid itself uses.
  void _computeGroupOffsets(BuildContext context, DeviceGalleryLoadSuccess state) {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = 4.0; // SliverPadding horizontal: 2 each side
    const spacing = 2.0;
    final columns = state.gridColumns;
    final itemSize = (screenWidth - horizontalPadding - (columns - 1) * spacing) / columns;

    final offsets = <double>[];
    final titles = <String>[];
    // Content now starts after the leading spacer sliver (see
    // _buildContent) — just kToolbarHeight now, since the status bar's own
    // height is handled separately by the Positioned clip, not by this
    // spacer. Group offsets must start from the same point, or the pill's
    // title lookup would be off by that amount.
    var cursor = kToolbarHeight;
    for (final group in state.groups) {
      offsets.add(cursor);
      titles.add(group.title);
      final rows = (group.assets.length / columns).ceil();
      cursor += rows * itemSize + (rows - 1).clamp(0, 999999) * spacing;
    }
    _groupStartOffsets = offsets;
    _groupTitles = titles;
    if (_currentGroupTitle.value.isEmpty && titles.isNotEmpty) {
      _currentGroupTitle.value = titles.first;
    }
  }

  /// Shows the trash confirmation dialog, then (if confirmed) clears
  /// selection, puts up the non-dismissible delete overlay, and fires one
  /// DeletePhotoRequested per selected asset. The overlay is taken down by
  /// the DeleteBloc listener once every id in _pendingDeleteIds resolves.
  Future<void> _handleTrash(BuildContext context, DeviceGalleryState state) async {
    if (state is! DeviceGalleryLoadSuccess) return;
    final ids = state.selectedAssetIds.toList();
    if (ids.isEmpty) return;

    final confirmed = await showTrashConfirmationDialog(context, count: ids.length);
    if (!confirmed || !context.mounted) return;

    context.read<DeviceGalleryBloc>().add(const DeviceGallerySelectionCleared());

    setState(() {
      _pendingDeleteIds
        ..clear()
        ..addAll(ids);
      _deleteOverlayShown = true;
    });
    showDeletingOverlay(context);

    for (final id in ids) {
      context.read<DeleteBloc>().add(DeletePhotoRequested(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DeviceGalleryBloc, DeviceGalleryState>(
          listener: (context, state) {
            if (state is DeviceGalleryLoadFailure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
            } else if (state is DeviceGalleryLoadSuccess && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.errorMessage}')));
            }
          },
        ),
        BlocListener<UploadBloc, UploadState>(
          listener: (context, state) {
            if (state is UploadSuccess) {
              context.read<DeviceGalleryBloc>().add(DeviceGalleryBackupStatusChanged(state.assetId, isBackedUp: true));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup successful')));
            } else if (state is UploadFailure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: ${state.message}')));
            }
          },
        ),
        BlocListener<DeleteBloc, DeleteState>(
          listener: (context, state) {
            if (state is DeleteSuccess) {
              _pendingDeleteIds.remove(state.assetId);
              context.read<DeviceGalleryBloc>().add(DeviceGalleryBackupStatusChanged(state.assetId, isBackedUp: false));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
            } else if (state is DeleteFailure) {
              _pendingDeleteIds.remove(state.assetId);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: ${state.message}')));
            }
            // Once every id from the confirmed batch has resolved, dismiss
            // the non-dismissible loading overlay pushed in _handleTrash.
            if (_deleteOverlayShown && _pendingDeleteIds.isEmpty) {
              _deleteOverlayShown = false;
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
        ),
      ],
      child: BlocBuilder<DeviceGalleryBloc, DeviceGalleryState>(
        builder: (context, state) {
          final isSelectionMode = state is DeviceGalleryLoadSuccess && state.selectedAssetIds.isNotEmpty;

          if (state is DeviceGalleryLoadSuccess) {
            _computeGroupOffsets(context, state);
          }

          final selectedCount = state is DeviceGalleryLoadSuccess ? state.selectedAssetIds.length : 0;

          // Selection mode no longer branches into a separate Scaffold — it
          // used to, which is exactly why the date pill / three-dot stopped
          // appearing on scroll while selecting (that whole scroll-linked
          // overlay lived only in the other branch). Now both modes share the
          // same Stack; selection mode just swaps the top-left widget (count
          // chip instead of logo/toolbar) and adds the bottom action sheet,
          // while the scroll-driven scrim + date pill + "..." button behave
          // identically either way.
          return Scaffold(
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                // Positioned with a fixed top clips the CustomScrollView's own
                // viewport to start exactly at the status bar's bottom edge —
                // a scroll viewport always clips its own content to its box,
                // so nothing can ever paint above this line (unlike the old
                // Padding/Opacity approach, which only hid it visually while
                // still letting it scroll behind the status bar icons).
                Positioned.fill(
                  top: MediaQuery.of(context).padding.top,
                  child: _buildContent(context, state, reserveToolbarSpace: !isSelectionMode),
                ),
                // The normal toolbar (logo, backup status, folder/+/bell/avatar)
                // fades out as the user scrolls down, and is fully hidden (not
                // just faded) in selection mode — the count chip below takes
                // its place instead. Painted BELOW the scrim/pill/button
                // layers so it never washes over them mid-crossfade.
                if (!isSelectionMode)
                  ValueListenableBuilder<double>(
                    valueListenable: _scrollProgress,
                    builder: (context, progress, _) {
                      return IgnorePointer(
                        ignoring: progress > 0.5,
                        child: Opacity(opacity: 1 - progress, child: _buildToolbar(context, state)),
                      );
                    },
                  ),
                // Selection count chip: always fully visible (this is an
                // explicit user action, it shouldn't fade with scroll like the
                // browse toolbar does), pinned top-left at the same height the
                // toolbar/pill row uses.
                if (isSelectionMode)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    child: SelectionCountPill(
                      count: selectedCount,
                      onClose: () => context.read<DeviceGalleryBloc>().add(const DeviceGallerySelectionCleared()),
                    ),
                  ),
                // Status bar scrim + floating date pill/"..." button — these
                // fade in with scroll progress in BOTH modes now. They sit
                // beside the count chip (center + right) rather than
                // overlapping it.
                ValueListenableBuilder<double>(
                  valueListenable: _scrollProgress,
                  builder: (context, progress, _) {
                    return IgnorePointer(
                      ignoring: progress < 0.5,
                      child: Opacity(opacity: progress, child: const TopStatusBarScrim()),
                    );
                  },
                ),
                ValueListenableBuilder<double>(
                  valueListenable: _scrollProgress,
                  builder: (context, progress, _) {
                    final topOffset = MediaQuery.of(context).padding.top + 8;
                    return IgnorePointer(
                      ignoring: progress < 0.5,
                      child: Opacity(
                        opacity: progress,
                        child: Stack(
                          children: [
                            // Date pill: physically centered top, regardless of
                            // RTL/LTR — Positioned/Align use physical
                            // coordinates, unlike Row's start/end.
                            Positioned(
                              top: topOffset,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: ValueListenableBuilder<String>(
                                  valueListenable: _currentGroupTitle,
                                  builder: (context, title, _) {
                                    return AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 150),
                                      child: FloatingDatePill(title: title),
                                    );
                                  },
                                ),
                              ),
                            ),
                            // More button: pinned to the physical right edge.
                            Positioned(
                              top: topOffset,
                              right: 16,
                              child: FloatingMoreButton(
                                onTap: () {
                                  final galleryBloc = context.read<DeviceGalleryBloc>();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => BlocProvider.value(value: galleryBloc, child: const PhotosViewStubScreen()),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Selection action sheet: pinned to the bottom, always fully
                // visible while selecting. MainNavigationScreen hides its own
                // floating nav bar while this is up (see BlocBuilder there),
                // so this no longer renders underneath it.
                if (isSelectionMode)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: SelectionActionSheet(
                        onBackUp: () {
                          if (state is DeviceGalleryLoadSuccess) {
                            for (final id in state.selectedAssetIds) {
                              context.read<UploadBloc>().add(UploadPhotoRequested(assetId: id));
                            }
                            context.read<DeviceGalleryBloc>().add(const DeviceGallerySelectionCleared());
                          }
                        },
                        onTrash: () => _handleTrash(context, state),
                        onDeleteFromDevice: () {
                          context.read<DeviceGalleryBloc>().add(const DeviceGallerySelectionCleared());
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('Delete from device coming soon')));
                        },
                        onStub: (label) => ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$label is coming soon'))),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// The normal (non-collapsed) toolbar row, painted as a plain white bar
  /// rather than a Scaffold AppBar so it can live inside the fading Stack.
  Widget _buildToolbar(BuildContext context, DeviceGalleryState state) {
    var backupStatus = 'Backup is off';
    if (state is DeviceGalleryLoadSuccess) {
      backupStatus = state.isAutoBackupEnabled ? 'Backup is on' : 'Backup is off';
    }

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Image.asset('assets/app_icon.png', height: 28),
            const SizedBox(width: 4),
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<DeviceGalleryBloc>(),
                        child: const BackupSettingsScreen(),
                      ),
                    ),
                  );
                },
                child: Text(backupStatus, style: const TextStyle(fontSize: 12)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.folder_outlined, color: AppColors.grey800),
              onPressed: () {},
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.grey800),
                  onPressed: () {},
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.googleRed, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.grey800),
              onPressed: () {},
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12, left: 4),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.grey200,
                child: Icon(Icons.person, size: 18, color: AppColors.grey700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DeviceGalleryState state, {bool reserveToolbarSpace = true}) {
    if (state is DeviceGalleryLoadInProgress) {
      return Padding(
        padding: EdgeInsets.only(top: reserveToolbarSpace ? kToolbarHeight : 0),
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (state is DeviceGalleryLoadSuccess) {
      if (state.groups.isEmpty) {
        return Padding(
          padding: EdgeInsets.only(top: reserveToolbarSpace ? kToolbarHeight : 0),
          child: const Center(child: Text('No photos found on device')),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          context.read<DeviceGalleryBloc>().add(const DeviceGalleryRequested());
        },
        child: CustomScrollView(
          controller: _scrollController,
          cacheExtent: 1000, // Pre-render items outside view for smoother scrolling
          slivers: [
            if (reserveToolbarSpace) const SliverToBoxAdapter(child: SizedBox(height: kToolbarHeight)),
            ...state.groups.expand((group) {
              final allInGroupSelected =
                  state.selectedAssetIds.isNotEmpty && group.assets.every((a) => state.selectedAssetIds.contains(a.id));

              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.grey800),
                          ),
                        ),
                        if (state.selectedAssetIds.isNotEmpty)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              allInGroupSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: allInGroupSelected ? AppColors.primary : AppColors.grey500,
                              size: 22,
                            ),
                            onPressed: () {
                              context.read<DeviceGalleryBloc>().add(DeviceGalleryGroupSelectionToggled(group.title));
                            },
                          ),
                      ],
                    ),
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
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final asset = group.assets[index];

                      return LocalPhotoGridItem(
                        key: ValueKey(asset.id),
                        asset: asset,
                        onTap: () {
                          if (state.selectedAssetIds.isNotEmpty) {
                            context.read<DeviceGalleryBloc>().add(DeviceGallerySelectionToggled(asset.id));
                          } else {
                            final allAssets = state.groups.expand((g) => g.assets).toList();
                            final galleryBloc = context.read<DeviceGalleryBloc>();

                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => BlocProvider.value(
                                  value: galleryBloc,
                                  child: LocalPhotoDetailScreen(
                                    assets: allAssets
                                        .map(
                                          (a) => AssetEntity(
                                            id: a.id,
                                            typeInt: AssetType.image.index,
                                            width: a.width ?? 0,
                                            height: a.height ?? 0,
                                            duration: a.duration?.inSeconds ?? 0,
                                          ),
                                        )
                                        .toList(),
                                    initialIndex: allAssets.indexOf(asset),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        onLongPress: () {
                          context.read<DeviceGalleryBloc>().add(DeviceGallerySelectionToggled(asset.id));
                        },
                      );
                    }, childCount: group.assets.length),
                  ),
                ),
              ];
            }),
            // Bottom clearance so the last row never scrolls under the
            // floating nav bar (normal mode) or the selection action sheet
            // (selection mode) — both sit on top of the system gesture bar,
            // so the system inset alone (previously ignored here) wasn't
            // enough.
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 110)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class TopStatusBarScrim extends StatelessWidget {
  const TopStatusBarScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: MediaQuery.of(context).padding.top, color: AppColors.white.withValues(alpha: 0.9));
  }
}

class FloatingDatePill extends StatelessWidget {
  const FloatingDatePill({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.layoutSegmentBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.layoutIconMuted),
      ),
    );
  }
}

class FloatingMoreButton extends StatelessWidget {
  const FloatingMoreButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.layoutSegmentBackground,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.more_vert, size: 20, color: AppColors.layoutIconMuted),
      ),
    );
  }
}

/// Same cream tone as the date pill / "Back up now" chip elsewhere — floating
/// "X  <count>" indicator shown in selection mode instead of the date pill.
class SelectionCountPill extends StatelessWidget {
  const SelectionCountPill({required this.count, required this.onClose, super.key});

  final int count;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.layoutSegmentBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, size: 20, color: AppColors.layoutIconMuted),
          ),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.layoutIconMuted),
          ),
        ],
      ),
    );
  }
}

class _SelectionAction {
  const _SelectionAction(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// Horizontally-scrolling sheet of selection actions, styled like a bottom
/// sheet (drag handle, rounded top corners) even though it's not a modal —
/// it just sits pinned above the system nav bar while items are selected.
/// Only "Back up" is wired to a real bloc event; the rest don't have a
/// device-side implementation yet, so they're stubbed with a snackbar
/// (same pattern as EmptyStateScreen / PhotosViewStubScreen elsewhere in
/// this app) rather than inventing behavior that isn't there.
class SelectionActionSheet extends StatelessWidget {
  const SelectionActionSheet({
    required this.onBackUp,
    required this.onTrash,
    required this.onDeleteFromDevice,
    required this.onStub,
    super.key,
  });

  final VoidCallback onBackUp;
  final VoidCallback onTrash;
  final VoidCallback onDeleteFromDevice;
  final void Function(String label) onStub;

  static const List<_SelectionAction> _actions = [
    _SelectionAction(Icons.share_outlined, 'Share'),
    _SelectionAction(Icons.playlist_add, 'Add to album'),
    _SelectionAction(Icons.add, 'Create'),
    _SelectionAction(Icons.delete_outline, 'Trash'),
    _SelectionAction(Icons.shopping_cart_outlined, 'Order photo'),
    _SelectionAction(Icons.cloud_upload_outlined, 'Back up'),
    _SelectionAction(Icons.move_to_inbox_outlined, 'Move to Archive'),
    _SelectionAction(Icons.phonelink_erase_outlined, 'Delete from device'),
    _SelectionAction(Icons.edit_location_alt_outlined, 'Edit location'),
    _SelectionAction(Icons.lock_outline, 'Move to Locked Folder'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: AppColors.peachSelected, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 68,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _actions.length,
              itemBuilder: (context, index) {
                final action = _actions[index];
                if (action.label == 'Back up') {
                  return _SelectionActionButton(icon: action.icon, label: action.label, onTap: onBackUp);
                }
                if (action.label == 'Trash') {
                  return _SelectionActionButton(icon: action.icon, label: action.label, onTap: onTrash);
                }
                if (action.label == 'Delete from device') {
                  return _SelectionActionButton(icon: action.icon, label: action.label, onTap: onDeleteFromDevice);
                }
                return _SelectionActionButton(
                  icon: action.icon,
                  label: action.label,
                  onTap: () => onStub(action.label),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SelectionActionButton extends StatelessWidget {
  const _SelectionActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: AppColors.layoutIconMuted),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.layoutIconMuted),
            ),
          ],
        ),
      ),
    );
  }
}
