// lib/presentation/widgets/todo_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mark_it_down_v2/routing/app_router.dart';

import '../../data/models/todo.dart';
import '../notifiers/todo_list_notifier.dart';
import 'due_date_chip.dart';
import 'priority_indicator.dart';

class TodoItem extends ConsumerStatefulWidget {
  final Todo todo;

  const TodoItem({super.key, required this.todo});

  @override
  ConsumerState<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends ConsumerState<TodoItem> {
  bool _isExpanded = false;

  String _getCompletionText(Todo todo) {
    if (todo.subTasks.isEmpty) return '';
    final completedCount = todo.subTasks.where((st) => st.completed).length;
    return '$completedCount / ${todo.subTasks.length} completed';
  }

  double _getCompletionValue(Todo todo) {
    if (todo.subTasks.isEmpty) return 0.0;
    final completedCount = todo.subTasks.where((st) => st.completed).length;
    return completedCount / todo.subTasks.length;
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    // final controller = ref.read(homeControllerProvider);
    final theme = Theme.of(context);
    final hasSubtasks = todo.subTasks.isNotEmpty;

    return Card(
      child: Dismissible(
        key: ValueKey(todo.id),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          ref.read(todoListProvider.notifier).remove(todo.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Todo deleted'),
              action: SnackBarAction(label: 'Undo', onPressed: () => ref.read(todoListProvider.notifier).refresh()),
            ),
          );
        },
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Column(
          children: [
            ListTile(
              enableFeedback: true,
              contentPadding: const EdgeInsets.only(left: 8.0, right: 0),
              leading: PriorityIndicator(priority: todo.priority),
              title: Row(
                children: [
                  // Custom animated checkbox
                  GestureDetector(
                    onTap: () => ref.read(todoListProvider.notifier).toggle(todo.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: todo.completed ? theme.colorScheme.secondary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: todo.completed
                            ? const Icon(Icons.check, size: 18.0, color: Colors.white)
                            : const SizedBox(width: 18.0, height: 18.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      todo.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        decoration: todo.completed ? TextDecoration.lineThrough : null,
                        color: todo.completed ? Colors.grey.shade600 : null,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 52.0),
                child: Row(
                  children: [
                    DueDateChip(dueDate: todo.dueDate),
                    if (hasSubtasks) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getCompletionText(todo),
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )
                    ]
                  ],
                ),
              ).animate(delay: 200.ms).fade().slideY(begin: 0.5, duration: 300.ms),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Edit Task',
                    onPressed: () => context.push(AppRoutes.edit, extra: todo),
                  ),
                  IconButton(
                    icon: Icon(Icons.play_circle_outline, color: theme.colorScheme.primary),
                    tooltip: 'Start Focus Session',
                    onPressed: () => context.push(AppRoutes.focus, extra: todo),
                  ),
                  if (hasSubtasks)
                    IconButton(
                      icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 20),
                      tooltip: _isExpanded ? 'Hide Sub-tasks' : 'Show Sub-tasks',
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    ),
                  if (!hasSubtasks) const SizedBox(width: 48) // To align with items that have expand icon
                ],
              ),
              onTap: () => context.push(AppRoutes.edit, extra: todo),
            ),
            if (hasSubtasks)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  child: !_isExpanded
                      ? LinearProgressIndicator(
                          value: _getCompletionValue(todo),
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          minHeight: 2,
                        ).animate().fade(duration: 200.ms)
                      : Column(
                          children: [
                            Divider(height: 1, thickness: 1, color: theme.dividerColor.withOpacity(0.5)),
                            ...todo.subTasks.map((subtask) {
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.only(left: 52.0),
                                leading: Checkbox(
                                  value: subtask.completed,
                                  onChanged: (val) {
                                    ref.read(todoListProvider.notifier).updateSubTask(subtask.copyWith(completed: val));
                                  },
                                ),
                                title: Text(subtask.title),
                              );
                            })
                          ],
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}