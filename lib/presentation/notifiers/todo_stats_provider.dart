// lib/presentation/notifiers/todo_stats_provider.dart
import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/todo.dart';
import 'todo_list_notifier.dart';

part 'todo_stats_provider.g.dart';

// A more detailed record to hold our enhanced stats
typedef TodoStats = ({
  int total,
  int completed,
  int active,
  double percentCompleted,
  // New data for charts
  Map<Priority, int> completedByPriority,
  Map<int, int> weeklyCompletion, // Key: weekday (1-7), Value: count
});

@riverpod
TodoStats todoStats(Ref ref) {
  final todos = ref.watch(todoListProvider).valueOrNull ?? [];
  final completedTodos = todos.where((t) => t.completed).toList();

  final total = todos.length;
  final completed = completedTodos.length;
  final active = total - completed;
  final percentCompleted = total == 0 ? 0.0 : (completed / total); // Keep as a fraction (0.0 to 1.0) for charts

  // 1. Calculate stats for the Priority Pie Chart
  final completedByPriority = groupBy<Todo, Priority>(
    completedTodos,
    (todo) => todo.priority,
  ).map((key, value) => MapEntry(key, value.length));

  // Ensure all priorities are present in the map, even if count is 0
  for (final priority in Priority.values) {
    if (priority != Priority.none) {
      completedByPriority.putIfAbsent(priority, () => 0);
    }
  }

  // 2. Calculate stats for the Weekly Bar Chart
  final weeklyCompletion = <int, int>{};
  final now = DateTime.now();
  final aWeekAgo = now.subtract(const Duration(days: 6));

  // Initialize the map with 0 counts for the last 7 days
  for (int i = 0; i < 7; i++) {
    final day = aWeekAgo.add(Duration(days: i));
    weeklyCompletion[day.weekday] = 0;
  }
  
  // Populate with actual data
  final recentCompletions = completedTodos.where((todo) {
    // Assuming createdAt is when it was completed for this stat
    // A more robust implementation might use a `completedAt` timestamp
    return !todo.createdAt.isBefore(DateTime(aWeekAgo.year, aWeekAgo.month, aWeekAgo.day));
  });

  for (final todo in recentCompletions) {
    weeklyCompletion.update(todo.createdAt.weekday, (value) => value + 1);
  }

  return (
    total: total,
    completed: completed,
    active: active,
    percentCompleted: percentCompleted,
    completedByPriority: completedByPriority,
    weeklyCompletion: weeklyCompletion,
  );
}