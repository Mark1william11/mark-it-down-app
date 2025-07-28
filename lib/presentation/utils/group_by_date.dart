// lib/presentation/utils/group_by_date.dart
import 'package:intl/intl.dart';
import '../../data/models/todo.dart';

// Groups a list of todos into a Map where keys are date strings
// (like "Today", "Yesterday") and values are lists of todos for that date.
Map<String, List<Todo>> groupByDate(List<Todo> todos) {
  final Map<String, List<Todo>> grouped = {};
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  for (final todo in todos) {
    final todoDate = DateTime(todo.createdAt.year, todo.createdAt.month, todo.createdAt.day);
    String key;

    if (todoDate == today) {
      key = 'Today';
    } else if (todoDate == yesterday) {
      key = 'Yesterday';
    } else {
      key = DateFormat.yMMMd().format(todoDate); // e.g., "Oct 25, 2023"
    }

    if (grouped[key] == null) {
      grouped[key] = [];
    }
    grouped[key]!.add(todo);
  }
  return grouped;
}