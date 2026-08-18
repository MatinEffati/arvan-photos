import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/features/photos/presentation/screens/photos_view_stub_screen.dart';
import 'package:flutter/material.dart';

class DateSectionHeader extends StatelessWidget {
  const DateSectionHeader({
    required this.title,
    required this.isSelected,
    required this.onToggleSelection,
    required this.isSelectionMode,
    super.key,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onToggleSelection;
  final bool isSelectionMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (isSelectionMode)
            IconButton(
              onPressed: onToggleSelection,
              icon: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppColors.primary : AppColors.grey500,
              ),
            ),
        ],
      ),
    );
  }
}
