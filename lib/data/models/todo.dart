// lib/data/models/todo.dart
import 'package:flutter/foundation.dart';

enum Priority { none, low, medium, high }

@immutable
class SubTask {
  final int id;
  final int todoId;
  final String? userId;
  final String title;
  final bool completed;

  const SubTask({
    required this.id,
    this.userId,
    required this.todoId,
    required this.title,
    this.completed = false,
  });

  SubTask copyWith({int? id, int? todoId, String? title, bool? completed, String? userId,}) {
    return SubTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      todoId: todoId ?? this.todoId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}

@immutable
class Todo {
  final int id;
  final String title;
  final bool completed;
  final DateTime createdAt;
  final DateTime? dueDate;
  final Priority priority;
  final int durationMinutes;
  final List<SubTask> subTasks; // New field

  const Todo({
    required this.id,
    required this.title,
    required this.createdAt,
    this.dueDate,
    this.priority = Priority.none,
    this.durationMinutes = 25,
    this.completed = false,
    this.subTasks = const [], String? userId, // Default to an empty list
  });

  // copyWith remains the same, but we add subTasks
  Todo copyWith({
    int? id,
    String? title,
    bool? completed,
    DateTime? createdAt,
    ValueGetter<DateTime?>? dueDate,
    Priority? priority,
    int? durationMinutes,
    List<SubTask>? subTasks,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      priority: priority ?? this.priority,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      subTasks: subTasks ?? this.subTasks,
    );
  }
}
