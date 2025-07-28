// lib/presentation/widgets/completed_section_header.dart
import 'package:confetti/confetti.dart' show ConfettiController;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/todo_list_notifier.dart';

class CompletedSectionHeader extends ConsumerWidget {
  final int completedCount;
  final VoidCallback onToggle;
  final bool isExpanded;
  final ConfettiController confettiController;

  const CompletedSectionHeader({
    super.key,
    required this.completedCount,
    required this.onToggle,
    required this.isExpanded,
    required this.confettiController,
  });

    @override
  Widget build(BuildContext context, WidgetRef ref) {
    // THE FIX: Return the Padding widget directly. It's a "Box" widget.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8), // Adjusted padding for new design
      child: InkWell(
        onTap: onToggle,
        // Make the InkWell's splash effect rounded
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Text(
              'Completed ($completedCount)',
              style: Theme.of(context).textTheme.titleMedium, // Adjusted style
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                ref.read(todoListProvider.notifier).clearCompleted();
                // We don't need confetti on clear, only on finishing all tasks.
                // confettiController.play(); 
              },
              child: const Text('Clear All'),
            ),
            Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
      ),
    );
  }
}
