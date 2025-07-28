// lib/presentation/widgets/due_date_chip.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DueDateChip extends StatelessWidget {
  final DateTime? dueDate;
  const DueDateChip({super.key, this.dueDate});

  @override
  Widget build(BuildContext context) {
    if (dueDate == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final chipDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    String label;
    Color color;

    if (chipDate.isBefore(today)) {
      label = 'Overdue';
      color = theme.colorScheme.error;
    } else if (chipDate == today) {
      label = 'Due Today';
      color = theme.colorScheme.secondary;
    } else if (chipDate == tomorrow) {
      label = 'Due Tomorrow';
      color = theme.colorScheme.primary;
    } else {
      label = DateFormat.MMMd().format(dueDate!);
      color = theme.colorScheme.onSurface.withOpacity(0.7);
    }

    return Chip(
      label: Text(label),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}