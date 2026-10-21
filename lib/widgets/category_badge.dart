// lib/widgets/category_badge.dart
//
// Live-updating category badge shown above the input fields.
// Animates (scale + fade) whenever the category changes.

import 'package:flutter/material.dart';
import '../data/models/category_meta.dart';

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category});
  final CategoryMeta category;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: category.color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                category.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: category.color,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
