import 'package:arvan_photos/core/di/injection.dart';
import 'package:arvan_photos/core/presentation/widgets/empty_state_screen.dart';
import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/core/theme/app_spacing.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/delete/delete_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/upload/upload_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/screens/device_gallery_screen.dart';
import 'package:arvan_photos/features/photos/presentation/widgets/floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Main navigation container. Tabs for Collection, Create, and Search are currently
/// stubs with empty states per project scope decisions.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      // DeviceGalleryScreen no longer creates its own DeviceGalleryBloc — the
      // BlocProvider now wraps this whole screen (see build() below) so the
      // floating nav bar can also read selection state and hide itself
      // while the Photos tab's selection action sheet is up.
      const DeviceGalleryScreen(),
      const EmptyStateScreen(title: 'Collection', message: 'Collection functionality will be implemented later.'),
      const EmptyStateScreen(title: 'Create', message: 'Create functionality will be implemented later.'),
      const EmptyStateScreen(title: 'Search', message: 'Search functionality will be implemented later.'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => getIt<DeviceGalleryBloc>()),
          BlocProvider(create: (context) => getIt<UploadBloc>()),
          BlocProvider(create: (context) => getIt<DeleteBloc>()),
        ],
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: Stack(
            children: [
              SafeArea(
                top: false,
                child: IndexedStack(index: _selectedIndex, children: _screens),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BlocBuilder<DeviceGalleryBloc, DeviceGalleryState>(
                  builder: (context, state) {
                    final isPhotosSelectionMode =
                        _selectedIndex == 0 && state is DeviceGalleryLoadSuccess && state.selectedAssetIds.isNotEmpty;

                    return IgnorePointer(
                      ignoring: isPhotosSelectionMode,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: isPhotosSelectionMode ? 0 : 1,
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.m),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: FloatingNavBar(
                                    selectedIndex: _selectedIndex,
                                    onItemSelected: (index) {
                                      setState(() {
                                        _selectedIndex = index;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s),
                                FloatingSearchButton(
                                  isSelected: _selectedIndex == 3,
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = 3;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
