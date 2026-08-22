import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Google Photos-style "Move to trash?" confirmation.
/// Returns true if confirmed, false if cancelled/dismissed.
Future<bool> showTrashConfirmationDialog(BuildContext context, {required int count}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.delete_outline, size: 28, color: AppColors.primary),
      iconPadding: const EdgeInsets.only(top: 24, bottom: 12),
      titlePadding: const EdgeInsets.symmetric(horizontal: 24),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      title: Text(
        count > 1 ? 'Move $count photos to trash?' : 'Move this photo to trash?',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: const Text(
        'Remove from your Google Account, any other devices with backup turned '
        'on and places shared within Google Photos?',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: AppColors.grey750),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel', style: TextStyle(color: AppColors.primary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Move to trash', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Small non-dismissible spinner shown while the delete request is in flight.
void showDeletingOverlay(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(
        child: SizedBox(
          width: 56,
          height: 56,
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        ),
      ),
    ),
  );
}
