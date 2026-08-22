import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/screens/backup_settings_screen.dart';
import 'package:arvan_photos/features/photos/presentation/screens/local_photo_detail_screen.dart';
import 'package:arvan_photos/features/photos/presentation/screens/photos_view_stub_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeviceGalleryBloc, DeviceGalleryState>(
      listener: (context, state) {
        if (state is DeviceGalleryLoadFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
        } else if (state is DeviceGalleryLoadSuccess && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.errorMessage}')));
        }
      },
      builder: (context, state) {
        final isSelectionMode = state is DeviceGalleryLoadSuccess && state.selectedAssetIds.isNotEmpty;

        if (state is DeviceGalleryLoadSuccess) {
          _computeGroupOffsets(context, state);
        }

        // Selection mode keeps a normal, always-opaque AppBar (it's an
        // explicit user action, it shouldn't fade away on scroll).
        if (isSelectionMode) {
          return Scaffold(
            appBar: _buildSelectionAppBar(context, state),
            body: _buildContent(context, state, reserveToolbarSpace: false),
          );
        }

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
              Positioned.fill(top: MediaQuery.of(context).padding.top, child: _buildContent(context, state)),
              // The normal toolbar (logo, backup status, folder/+/bell/avatar)
              // fades out as the user scrolls down. Painted BELOW the
              // scrim/pill/button layers so it never washes over them
              // mid-crossfade.
              ValueListenableBuilder<double>(
                valueListenable: _scrollProgress,
                builder: (context, progress, _) {
                  return IgnorePointer(
                    ignoring: progress > 0.5,
                    child: Opacity(opacity: 1 - progress, child: _buildToolbar(context, state)),
                  );
                },
              ),
              // Status bar scrim + floating pill/button only fade in once the
              // toolbar underneath has (mostly) faded out. These are true
              // overlays with nothing behind them but the photo grid —
              // no enclosing bar, just the pill/button's own shadow, like a
              // FAB floating over content.
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
                              // TODO: open the per-photo view / menu.
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(BuildContext context, DeviceGalleryLoadSuccess state) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.read<DeviceGalleryBloc>().add(const DeviceGallerySelectAllToggled()),
      ),
      title: Text('${state.selectedAssetIds.length} selected'),
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
      color: Colors.white,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Image.asset('assets/app_icon.png', height: 28),
            const SizedBox(width: 12),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Photos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3C4043),
                      ),
                    ),
                    Text(
                      backupStatus,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5F6368),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.folder_outlined, color: Color(0xFF3C4043)),
              onPressed: () {
                final galleryBloc = context.read<DeviceGalleryBloc>();
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider.value(value: galleryBloc, child: const PhotosViewStubScreen()),
                  ),
                );
              },
              tooltip: 'Photos view',
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF3C4043)),
                  onPressed: () {},
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF3C4043)),
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
              return [
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
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
    return Container(height: MediaQuery.of(context).padding.top, color: Colors.white.withValues(alpha: 0.9));
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF3C4043)),
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
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.more_vert, size: 20, color: Color(0xFF3C4043)),
      ),
    );
  }
}
