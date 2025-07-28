// lib/presentation/notifiers/todo_list_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/todo.dart' as model;
import '../../logic/sorting_logic.dart';
import '../../logic/todo_service.dart';

part 'todo_list_notifier.g.dart';

enum TodoFilter { all, active, completed }

final filterStateProvider = StateProvider<TodoFilter>((ref) => TodoFilter.all);
final searchStateProvider = StateProvider<String>((ref) => '');
final searchVisibleProvider = StateProvider<bool>((ref) => false);

typedef FilteredTodoLists = ({
  List<model.Todo> active,
  List<model.Todo> completed,
});

@riverpod
FilteredTodoLists filteredTodos(Ref ref) {
  final filter = ref.watch(filterStateProvider);
  final todos = ref.watch(todoListProvider).valueOrNull ?? [];
  final searchQuery = ref.watch(searchStateProvider);
  final sortOption =
      ref.watch(sortPreferenceProvider).valueOrNull ??
      SortOption.creationDateDesc;

  List<model.Todo> searchedTodos;
  if (searchQuery.isNotEmpty) {
    searchedTodos = todos.where((todo) {
      return todo.title.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  } else {
    searchedTodos = todos;
  }

  final activeTodos = searchedTodos.where((t) => !t.completed).toList();
  final completedTodos = searchedTodos.where((t) => t.completed).toList();

  activeTodos.sort((a, b) {
    switch (sortOption) {
      case SortOption.creationDateDesc:
        return b.createdAt.compareTo(a.createdAt);
      case SortOption.creationDateAsc:
        return a.createdAt.compareTo(b.createdAt);
      case SortOption.priority:
        return a.priority.index.compareTo(b.priority.index);
      case SortOption.dueDate:
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
    }
  });
  completedTodos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  switch (filter) {
    case TodoFilter.active:
      return (active: activeTodos, completed: []);
    case TodoFilter.completed:
      return (active: [], completed: completedTodos);
    case TodoFilter.all:
      return (active: activeTodos, completed: completedTodos);
  }
}

@riverpod
class TodoList extends _$TodoList {
  TodoService get _service => ref.read(todoServiceProvider);

  @override
  Future<List<model.Todo>> build() async {
    return _service.getTodos();
  }

  Future<void> addTodo({
    required String title,
    model.Priority priority = model.Priority.none,
    DateTime? dueDate,
    int durationMinutes = 25,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // NOTE: We don't use the returned ID here, but the controller will.
      await _service.addTodo(
        title: title,
        priority: priority,
        dueDate: dueDate,
        durationMinutes: durationMinutes,
      );
      return _service.getTodos();
    });
  }

  Future<void> edit({
    required int id,
    String? newTitle,
    ValueGetter<DateTime?>? dueDate,
    model.Priority? priority,
    int? durationMinutes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final todos = await _service.getTodos();
      // Find the existing todo to update, preserving its sub-tasks
      final todoToUpdate = todos.firstWhere((t) => t.id == id);
      await _service.updateTodo(
        todoToUpdate.copyWith(
          title: newTitle,
          dueDate: dueDate,
          priority: priority,
          durationMinutes: durationMinutes,
        ),
      );
      return _service.getTodos();
    });
  }

  // REPLACE the existing toggle method
  Future<void> toggle(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final todos = await _service.getTodos();
      final todoToUpdate = todos.firstWhere((t) => t.id == id);
      await _service.updateTodo(
        todoToUpdate.copyWith(completed: !todoToUpdate.completed)
      );
      return _service.getTodos();
    });
  }

  Future<void> remove(int id) async {
    final previousState = state;
    final oldTodos = previousState.valueOrNull;
    if (oldTodos == null) return;
    state = AsyncData(oldTodos.where((todo) => todo.id != id).toList());

    try {
      await _service.deleteTodo(id);
    } catch (e) {
      state = previousState;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getTodos());
  }

  Future<void> clearCompleted() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.clearCompleted();
      return _service.getTodos();
    });
  }

  Future<int> addSubTask(int todoId, String title) async {
    // This method needs to return the ID so the UI can update the new subtask
    final newId = await _service.addSubTask(todoId: todoId, title: title);
    await refresh(); // Refresh the list to get all updated data
    return newId;
  }

  Future<void> updateSubTask(model.SubTask subTask) async {
    state = await AsyncValue.guard(() async {
      await _service.updateSubTask(subTask);
      return _service.getTodos();
    });
  }
  
  Future<void> deleteSubTask(int subTaskId) async {
    state = await AsyncValue.guard(() async {
      await _service.deleteSubTask(subTaskId);
      return _service.getTodos();
    });
  }
}
