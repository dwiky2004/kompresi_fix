import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/theme.dart';

class UploadCard extends StatelessWidget {
  final VoidCallback onTap;
  final String? selectedImagePath;
  final Widget? imagePreview;

  const UploadCard({
    super.key,
    required this.onTap,
    this.selectedImagePath,
    this.imagePreview,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = selectedImagePath != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(
            color: hasImage
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.primary.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            if (!hasImage) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.image_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ketuk untuk mengunggah citra',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Format didukung: JPG, PNG',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ] else ...[
              imagePreview ??
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadius),
                    child: Image.file(
                      File(selectedImagePath!),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

