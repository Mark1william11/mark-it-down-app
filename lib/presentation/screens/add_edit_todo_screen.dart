// lib/presentation/screens/add_edit_todo_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mark_it_down_v2/routing/app_router.dart';
import '../../data/models/todo.dart';
import '../../logic/todo_service.dart';
import '../notifiers/todo_list_notifier.dart';

/// A helper class to manage the state of sub-tasks in the UI,
/// including their text controllers and original state for diffing.
class _EditableSubTask {
  final SubTask? original;
  final TextEditingController controller;
  bool isCompleted;
  final FocusNode focusNode;

  _EditableSubTask({this.original, required this.controller, required this.isCompleted, required this.focusNode});

  bool get isNew => original == null;
  bool get wasModified =>
      original == null ||
      original?.title != controller.text ||
      original?.completed != isCompleted;
}

class AddEditTodoScreen extends ConsumerStatefulWidget {
  final Todo? todo;
  const AddEditTodoScreen({super.key, this.todo});

  @override
  ConsumerState<AddEditTodoScreen> createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends ConsumerState<AddEditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late Priority _priority;
  late DateTime? _dueDate;
  late TextEditingController _durationController;
  
  // State for sub-tasks
  final List<_EditableSubTask> _subTasks = [];
  final Set<int> _subTasksToDelete = {};
  
  bool get isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    _titleController = TextEditingController(text: todo?.title ?? '');
    _priority = todo?.priority ?? Priority.none;
    _dueDate = todo?.dueDate;
    _durationController = TextEditingController(text: (todo?.durationMinutes ?? 25).toString());

    if (todo != null) {
      for (final subTask in todo.subTasks) {
        _subTasks.add(_EditableSubTask(
          original: subTask,
          controller: TextEditingController(text: subTask.title),
          isCompleted: subTask.completed,
          focusNode: FocusNode(),
        ));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    for (var sub in _subTasks) {
      sub.controller.dispose();
      sub.focusNode.dispose();
    }
    super.dispose();
  }

  void _addSubTask() {
    setState(() {
      final newSubTask = _EditableSubTask(
        controller: TextEditingController(),
        isCompleted: false,
        focusNode: FocusNode(),
      );
      _subTasks.add(newSubTask);

      // Request focus for the newly added sub-task field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        newSubTask.focusNode.requestFocus();
      });
    });
  }

  void _removeSubTask(int index) {
    setState(() {
      final subTask = _subTasks[index];
      if (!subTask.isNew) {
        _subTasksToDelete.add(subTask.original!.id);
      }
      subTask.controller.dispose();
      subTask.focusNode.dispose();
      _subTasks.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    
    // Using the notifier directly is simpler than using the controller here
    // because we need to coordinate multiple async operations.
    final notifier = ref.read(todoListProvider.notifier);
    final duration = int.tryParse(_durationController.text) ?? 25;

    try {
      int todoId;

      if (isEditing) {
        todoId = widget.todo!.id;
        await notifier.edit(
          id: todoId,
          newTitle: _titleController.text,
          priority: _priority,
          dueDate: () => _dueDate,
          durationMinutes: duration,
        );
      } else {
        // We can't use the simple notifier.addTodo because it refreshes too early.
        // We need the ID back before we can add sub-tasks.
        final todoService = ref.read(todoServiceProvider);
        todoId = await todoService.addTodo(
          title: _titleController.text,
          priority: _priority,
          dueDate: _dueDate,
          durationMinutes: duration,
        );
      }
      
      // Process sub-tasks
      for (final subTask in _subTasks) {
        if (subTask.controller.text.isEmpty) continue; // Skip empty ones

        if (subTask.isNew) {
          await notifier.addSubTask(todoId, subTask.controller.text);
        } else if (subTask.wasModified) {
          await notifier.updateSubTask(
            subTask.original!.copyWith(
              title: subTask.controller.text,
              completed: subTask.isCompleted,
            ),
          );
        }
      }

      // Delete sub-tasks that were removed
      for (final idToDelete in _subTasksToDelete) {
        await notifier.deleteSubTask(idToDelete);
      }
      
      // Finally, refresh the list to show all changes and navigate back
      if(!isEditing) await notifier.refresh();
      if (mounted) context.go(AppRoutes.home);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add New Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Save Task',
            onPressed: _submit,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Main Task Fields ---
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task Name', border: OutlineInputBorder()),
                autofocus: !isEditing,
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Focus Duration (minutes)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<Priority>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                items: Priority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (value) => setState(() => _priority = value!),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _dueDate == null ? 'No due date set' : DateFormat.yMMMd().format(_dueDate!),
                    ),
                  ),
                  TextButton(
                    child: Text(_dueDate == null ? 'Set Date' : 'Change'),
                    onPressed: () async {
                      final newDate = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (newDate != null) {
                        setState(() => _dueDate = newDate);
                      }
                    },
                  ),
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() => _dueDate = null),
                    )
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // --- Sub-tasks Section ---
              Text('Sub-tasks', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              if (_subTasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('No sub-tasks yet. Add one below!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subTasks.length,
                itemBuilder: (context, index) {
                  final subTask = _subTasks[index];
                  return Row(
                    children: [
                      Checkbox(
                        value: subTask.isCompleted,
                        onChanged: (val) => setState(() => subTask.isCompleted = val!),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: subTask.controller,
                          focusNode: subTask.focusNode,
                          decoration: const InputDecoration(hintText: 'Sub-task name...'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _removeSubTask(index),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Sub-task'),
                  onPressed: _addSubTask,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}