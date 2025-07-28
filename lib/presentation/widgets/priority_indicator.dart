// lib/presentation/widgets/priority_indicator.dart
import 'package:flutter/material.dart';
import '../../data/models/todo.dart';
import '../theme/app_theme.dart';

class PriorityIndicator extends StatelessWidget {
  final Priority priority;
  const PriorityIndicator({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (priority) {
      case Priority.high:
        // CORRECTED: Use the color from our theme definition
        color = AppTheme.highPriorityColor;
        break;
      case Priority.medium:
        // CORRECTED: Use the color from our theme definition
        color = AppTheme.mediumPriorityColor;
        break;
      case Priority.low:
        // CORRECTED: Use the color from our theme definition
        color = AppTheme.lowPriorityColor;
        break;
      case Priority.none:
        return const SizedBox.shrink();
    }

    return Container(
      width: 5,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}