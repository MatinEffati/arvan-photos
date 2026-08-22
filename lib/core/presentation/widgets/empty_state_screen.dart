import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class EmptyStateScreen extends StatelessWidget {
  const EmptyStateScreen({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty, size: 64, color: AppColors.grey400),
              const SizedBox(height: AppSpacing.m),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
