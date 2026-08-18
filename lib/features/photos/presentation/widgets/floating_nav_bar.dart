import 'package:arvan_photos/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class FloatingNavBar extends StatelessWidget {

  const FloatingNavBar({
    required this.selectedIndex, required this.onItemSelected, super.key,
  });
  final int selectedIndex;
  final Function(int ) onItemSelected;

  static const Color barBgColor = Color(0xFFFFF1E4);
  static const Color selectedItemColor = Color(0xFFFFDDBE);
  static const Color onSurfaceColor = Color(0xFF202124);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: 4, // Minimized horizontal padding
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: barBgColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavBarItem(
            icon: Icons.image,
            label: 'Photos',
            isSelected: selectedIndex == 0,
            onTap: () => onItemSelected(0),
          ),
          _NavBarItem(
            icon: Icons.cloud_outlined,
            label: 'Cloud',
            isSelected: selectedIndex == 1,
            onTap: () => onItemSelected(1),
          ),
          _NavBarItem(
            icon: Icons.collections_bookmark,
            label: 'Library',
            isSelected: selectedIndex == 2,
            onTap: () => onItemSelected(2),
          ),
          _NavBarItem(
            icon: Icons.add_box_outlined,
            label: 'Create',
            isSelected: selectedIndex == 3,
            onTap: () => onItemSelected(3),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? FloatingNavBar.selectedItemColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(icon, size: 18, color: FloatingNavBar.onSurfaceColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: FloatingNavBar.onSurfaceColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FloatingSearchButton extends StatelessWidget {

  const FloatingSearchButton({
    super.key,
    required this.isSelected,
    required this.onTap,
  });
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: FloatingNavBar.barBgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected
              ? Border.all(color: FloatingNavBar.selectedItemColor, width: 2)
              : null,
        ),
        child: const Icon(
          Icons.search,
          size: 28,
          color: FloatingNavBar.onSurfaceColor,
        ),
      ),
    );
  }
}
