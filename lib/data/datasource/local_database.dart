// lib/data/datasource/local_database.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/todo.dart' as model;

part 'local_database.g.dart';

// Main Todo table
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 50)();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get priority => integer().map(const PriorityConverter()).withDefault(const Constant(0))();
  IntColumn get durationMinutes => integer().withDefault(const Constant(25))();
}

// New SubTasks table
class SubTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get todoId => integer().named('todo_id').references(Todos, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}

// Add the new SubTasks table to the database annotation
@DriftDatabase(tables: [Todos, SubTasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Increment schema version
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(todos, todos.createdAt);
        }
        if (from < 3) {
          await m.addColumn(todos, todos.dueDate);
          await m.addColumn(todos, todos.priority);
        }
        if (from < 4) {
          await m.addColumn(todos, todos.durationMinutes);
        }
        // Add the migration step for the new table
        if (from < 5) {
          await m.createTable(subTasks);
        }
      },
    );
  }

  // --- Read Operation with Sub-tasks ---

  Future<List<model.Todo>> getTodos() async {
    // 1. Define the JOIN between todos and sub_tasks
    final query = select(todos).join([
      leftOuterJoin(subTasks, subTasks.todoId.equalsExp(todos.id)),
    ]);

    // 2. Execute the query
    final rows = await query.get();

    // 3. Process the results
    final groupedData = <int, List<model.SubTask>>{};

    for (final row in rows) {
      final todoData = row.readTable(todos);
      final subTaskData = row.readTableOrNull(subTasks);

      // Ensure the list for this todoId exists
      groupedData.putIfAbsent(todoData.id, () => []);

      if (subTaskData != null) {
        final subTaskModel = model.SubTask(
          id: subTaskData.id,
          todoId: subTaskData.todoId,
          title: subTaskData.title,
          completed: subTaskData.completed,
        );
        groupedData[todoData.id]!.add(subTaskModel);
      }
    }

    // 4. Map the raw data to our domain models
    return groupedData.entries.map((entry) {
      // Find the original todo row for this id
      final todoRow = rows.firstWhere((row) => row.readTable(todos).id == entry.key).readTable(todos);
      return model.Todo(
        id: todoRow.id,
        title: todoRow.title,
        completed: todoRow.completed,
        createdAt: todoRow.createdAt,
        dueDate: todoRow.dueDate,
        priority: todoRow.priority,
        durationMinutes: todoRow.durationMinutes,
        subTasks: entry.value,
      );
    }).toList();
  }

  // --- CUD Operations for Todos ---

  Future<int> addTodo({
    required String title,
    model.Priority priority = model.Priority.none,
    DateTime? dueDate,
    int durationMinutes = 25,
  }) {
    return into(todos).insert(TodosCompanion(
      title: Value(title),
      priority: Value(priority),
      dueDate: Value(dueDate),
      durationMinutes: Value(durationMinutes),
    ));
  }

  Future<void> updateTodo(model.Todo todo) {
    return (update(todos)..where((t) => t.id.equals(todo.id))).write(
      TodosCompanion(
        title: Value(todo.title),
        completed: Value(todo.completed),
        dueDate: Value(todo.dueDate),
        priority: Value(todo.priority),
        durationMinutes: Value(todo.durationMinutes),
      ),
    );
  }

  Future<int> deleteTodo(int id) {
    // Thanks to `onDelete: KeyAction.cascade`, Drift will automatically delete sub-tasks.
    return (delete(todos)..where((t) => t.id.equals(id))).go();
  }

  Future<int> clearCompleted() {
    return (delete(todos)..where((t) => t.completed.equals(true))).go();
  }

  // --- CUD Operations for Sub-tasks ---

  Future<int> addSubTask(int todoId, String title) {
    return into(subTasks).insert(SubTasksCompanion.insert(
      todoId: todoId,
      title: title,
    ));
  }

  Future<bool> updateSubTask(model.SubTask subTask) {
    return (update(subTasks)..where((t) => t.id.equals(subTask.id))).write(
      SubTasksCompanion(
        title: Value(subTask.title),
        completed: Value(subTask.completed),
      ),
    ).then((value) => value > 0);
  }

  Future<int> deleteSubTask(int subTaskId) {
    return (delete(subTasks)..where((t) => t.id.equals(subTaskId))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}

class PriorityConverter extends TypeConverter<model.Priority, int> {
  const PriorityConverter();
  @override
  model.Priority fromSql(int fromDb) {
    return model.Priority.values[fromDb];
  }

  @override
  int toSql(model.Priority value) {
    return value.index;
  }
}