import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class BackupActionBar extends StatelessWidget {
  const BackupActionBar({
    required this.selectedCount,
    required this.onBackupPressed,
    required this.onClearSelection,
    super.key,
  });

  final int selectedCount;
  final VoidCallback onBackupPressed;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: onClearSelection,
              icon: const Icon(Icons.close),
            ),
            const SizedBox(width: 8),
            Text(
              '$selectedCount selected',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: onBackupPressed,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Back Up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
