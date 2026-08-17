import 'package:arvan_photos/core/presentation/widgets/empty_state_screen.dart';
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
    const PhotosScreen(),
    const EmptyStateScreen(
      title: 'Search',
      message: 'Search functionality is not implemented yet.',
    ),
    const EmptyStateScreen(
      title: 'Library',
      message: 'Library functionality is not implemented yet.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            activeIcon: Icon(Icons.photo_library),
            label: 'Photos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}
