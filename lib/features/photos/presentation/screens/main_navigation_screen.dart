import 'package:arvan_photos/core/presentation/widgets/empty_state_screen.dart';
import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/features/photos/presentation/screens/device_gallery_screen.dart';
import 'package:arvan_photos/features/photos/presentation/screens/photos_screen.dart';
import 'package:flutter/material.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DeviceGalleryScreen(),
    const EmptyStateScreen(
      title: 'Search',
      message: 'Search functionality is not implemented yet.',
    ),
    const PhotosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library, color: AppColors.primary),
            label: 'Photos',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: AppColors.primary),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books, color: AppColors.primary),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}
