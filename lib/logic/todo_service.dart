// lib/logic/todo_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mark_it_down_v2/logic/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/todo.dart';
import '../data/repository/todo_repository.dart';

part 'todo_service.g.dart';

// The service class contains all our business logic.
// It is clean and has no dependency on Flutter or other UI packages.
class TodoService {
  final TodoRepository _repository;
  final NotificationService _notificationService;
  const TodoService(this._repository, this._notificationService);

  // --- Todo Logic ---

  Future<List<Todo>> getTodos() => _repository.getTodos();

  Future<int> addTodo({
    required String title,
    Priority priority = Priority.none,
    DateTime? dueDate,
    int durationMinutes = 25,
  }) {
    // This now correctly returns the ID of the new Todo
    return _repository.addTodo(
      title: title,
      priority: priority,
      dueDate: dueDate,
      durationMinutes: durationMinutes,
    );
  }

  Future<void> updateTodo(Todo todo) async {
    // Business logic: if a parent task is marked as incomplete,
    // we might want to un-complete its sub-tasks.
    // For now, we keep it simple. The core logic remains.
    final result = await _repository.updateTodo(todo);

    if (todo.completed) {
      await _notificationService.cancelTodoNotification(todo.id);
    } else {
      await _notificationService.scheduleTodoNotification(todo);
    }
    return result;
  }

  Future<void> deleteTodo(int id) async {
    await _repository.deleteTodo(id);
    // Cancel any pending notification for the deleted todo
    await _notificationService.cancelTodoNotification(id);
  }

  Future<void> clearCompleted() => _repository.clearCompleted();

  // --- Sub-task Logic ---

  Future<int> addSubTask({required int todoId, required String title}) {
    // Any business logic before adding a sub-task would go here.
    // For example, ensuring the parent task isn't completed.
    return _repository.addSubTask(todoId, title);
  }

  Future<void> updateSubTask(SubTask subTask) {
    // Business logic for updating a sub-task.
    return _repository.updateSubTask(subTask);
  }

  Future<void> deleteSubTask(int subTaskId) {
    // Business logic for deleting a sub-task.
    return _repository.deleteSubTask(subTaskId);
  }
}

// A simple provider to make the service available to the rest of the app.
@Riverpod(keepAlive: true)
TodoService todoService(Ref ref) {
  return TodoService(
    ref.watch(todoRepositoryProvider),
    ref.watch(notificationServiceProvider),
  );
}