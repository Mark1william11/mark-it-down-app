// lib/presentation/widgets/todo_item_skeleton.dart
import 'package:flutter/material.dart';

class TodoItemSkeleton extends StatelessWidget {
  const TodoItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // This color will be controlled by the Shimmer's baseColor.
    // By making the skeleton's color match, the effect is seamless.
    final placeholderColor = Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey[850]! 
        : Colors.grey[300]!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        // Match the padding of the real ListTile
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        
        // ADD a placeholder for the PriorityIndicator
        leading: Container(
          width: 5,
          height: 24,
          decoration: BoxDecoration(
            color: placeholderColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        // UPDATE the title to be a Row that matches the real ListTile
        title: Row(
          children: [
            // Placeholder for the Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: placeholderColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            // Placeholder for the Text
            Expanded(
              child: Container(
                height: 16.0,
                decoration: BoxDecoration(
                  color: placeholderColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}