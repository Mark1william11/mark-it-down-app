// lib/data/repository/todo_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mark_it_down_v2/logic/auth_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../datasource/local_database.dart';
import '../models/todo.dart' as model;

part 'todo_repository.g.dart';

@Riverpod(keepAlive: true)
TodoRepository todoRepository(Ref ref) {
  return TodoRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(authServiceProvider),
  );
}

class TodoRepository {
  final AppDatabase _db;
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TodoRepository(this._db, this._authService);

  String? get _userId => _authService.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _userTodosCollection {
    final userId = _userId;
    if (userId == null) throw Exception('User is not logged in.');
    return _firestore.collection('users').doc(userId).collection('todos');
  }

  // --- "OFFLINE FIRST" APPROACH ---

  // Read operation ALWAYS reads from the fast local database.
  Future<List<model.Todo>> getTodos() async {
    // We will sync from cloud in the background, but the UI gets an instant response.
    _syncFromCloud(); 
    return _db.getTodos();
  }

  // Write operation writes to local DB first, then syncs to cloud.
  Future<int> addTodo({
    required String title,
    model.Priority priority = model.Priority.none,
    DateTime? dueDate,
    int durationMinutes = 25,
  }) async {
    // 1. Write to the fast local DB immediately.
    final localId = await _db.addTodo(
      title: title, priority: priority, dueDate: dueDate, durationMinutes: durationMinutes);

    // 2. Sync this new item to the cloud in the background.
    // We don't 'await' this, so the UI is not blocked.
    _syncTodoToCloud(model.Todo(
      id: localId,
      userId: _userId,
      title: title,
      createdAt: DateTime.now(),
      priority: priority,
      dueDate: dueDate,
      durationMinutes: durationMinutes,
    ));
    
    return localId;
  }

  Future<void> updateTodo(model.Todo todo) async {
    // 1. Update local DB immediately.
    await _db.updateTodo(todo);
    // 2. Sync changes to the cloud.
    _syncTodoToCloud(todo);
  }

  Future<void> deleteTodo(int id) async {
    // 1. Delete from local DB immediately.
    await _db.deleteTodo(id);
    // 2. Sync deletion to the cloud.
    if (_userId != null) {
      _userTodosCollection.doc(id.toString()).delete().catchError((e) {
        print("Failed to delete todo from cloud: $e");
        // Optionally, implement a retry mechanism or flag for later sync.
      });
    }
  }

  // --- BACKGROUND SYNC LOGIC ---

  // Syncs a single Todo object to Firestore.
  Future<void> _syncTodoToCloud(model.Todo todo) async {
    if (_userId == null) return; // Can't sync if not logged in.

    final todoData = {
      'id': todo.id,
      'userId': _userId,
      'title': todo.title,
      'completed': todo.completed,
      'createdAt': Timestamp.fromDate(todo.createdAt),
      'dueDate': todo.dueDate != null ? Timestamp.fromDate(todo.dueDate!) : null,
      'priority': todo.priority.index,
      'durationMinutes': todo.durationMinutes,
      // NOTE: Sub-tasks are not part of the cloud model yet.
    };

    try {
      await _userTodosCollection.doc(todo.id.toString()).set(todoData);
    } catch (e) {
      print("Failed to sync todo to cloud: $e");
      // In a real app, you would add more robust error handling here,
      // like a queue for failed syncs.
    }
  }

  // Fetches all data from the cloud and overwrites the local database.
  // This is a simple "full refresh" sync.
  Future<void> _syncFromCloud() async {
    if (_userId == null) return;

    try {
      final snapshot = await _userTodosCollection.get();
      
      // A more advanced sync would merge local and remote changes.
      // For now, we clear the local DB and replace with cloud data.
      await _db.delete( _db.todos).go();
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        await _db.into(_db.todos).insert(
          TodosCompanion.insert(
            id: Value(data['id']),
            title: data['title'],
            completed: Value(data['completed']),
            createdAt: Value((data['createdAt'] as Timestamp).toDate()),
            dueDate: Value(data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null),
            priority: Value(model.Priority.values[data['priority']]),
            durationMinutes: Value(data['durationMinutes']),
          )
        );
      }
    } catch (e) {
      print("Failed to sync from cloud: $e");
      // If sync fails, the user can still use their local data, which is fine.
    }
  }

  // --- Local-Only Operations ---
  Future<void> clearCompleted() async {
    final todos = await _db.getTodos();
    for (final todo in todos.where((t) => t.completed)) {
      await deleteTodo(todo.id); // This will handle both local and cloud deletion
    }
  }
  
  Future<int> addSubTask(int todoId, String title) => _db.addSubTask(todoId, title);
  Future<void> updateSubTask(model.SubTask subTask) => _db.updateSubTask(subTask);
  Future<void> deleteSubTask(int subTaskId) => _db.deleteSubTask(subTaskId);
}