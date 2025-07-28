// lib/presentation/widgets/celebration_header.dart
import 'package:flutter/material.dart';

class CelebrationHeader extends StatelessWidget {
  const CelebrationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      child: Column(
        children: [
          Icon(
            Icons.celebration_rounded,
            size: 64,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'All tasks completed!',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Time to relax, or clear the list to start fresh.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}