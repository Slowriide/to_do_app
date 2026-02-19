import 'package:isar/isar.dart';
import 'package:to_do_app/data/models/isar_todo.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';

/// Isar implementation of [TodoRepository].
///
/// This class handles the persistence of todo items and their subtasks
/// using the Isar database.
class IsarTodoRepositoryImpl implements TodoRepository {
  final Isar db;
  IsarTodoRepositoryImpl(this.db);

  @override
  Future<void> addTodo(Todo newTodo) async {
    final todoIsar = TodoIsar.fromDomain(newTodo.copyWith(isSubtask: false));

    return db.writeTxn(() async {
      await db.todoIsars.put(todoIsar);

      if (newTodo.subTasks.isNotEmpty) {
        for (var subTasks in newTodo.subTasks) {
          final subTaskIsar =
              TodoIsar.fromDomain(subTasks.copyWith(isSubtask: true));
          await db.todoIsars.put(subTaskIsar);
          todoIsar.subtasks.add(subTaskIsar);
        }
        await todoIsar.subtasks.save();
        await db.todoIsars.put(todoIsar);
      }
    });
  }

  @override
  Future<void> deleteTodo(Todo todo) async {
    return db.writeTxn(() async {
      for (var subTasks in todo.subTasks) {
        await db.todoIsars.delete(subTasks.id);
      }

      await db.todoIsars.delete(todo.id);
    });
  }

  @override
  Future<List<Todo>> getTodos() async {
    final todos = await db.todoIsars.filter().isSubtaskEqualTo(false).findAll();

    for (var todo in todos) {
      await todo.subtasks.load();
    }

    return todos
        .where((todo) => !todo.isSubtask)
        .map((todo) => todo.toDomain())
        .toList();
  }

  @override
  Future<void> addSubTask(Todo subtask, int todoId) async {
    final todoIsarById = await db.todoIsars.get(todoId); //get todo by id

    if (todoIsarById == null) {
      throw Exception("Todo with id $todoId not found.");
    }

    final subTaskIsar = TodoIsar.fromDomain(subtask);
    return db.writeTxn(() async {
      //save subtask in db
      await db.todoIsars.put(subTaskIsar);

      //add subtast to todo
      todoIsarById.subtasks.add(subTaskIsar);
      await todoIsarById.subtasks.save(); //save the realtion in todo

      //refresh todo with the new subtask
      await db.todoIsars.put(todoIsarById);
    });
  }

  @override
  Future<void> updateTodo(Todo todo) async {
    await updateTodos([todo]);
  }

  @override
  Future<void> updateTodos(List<Todo> todos) async {
    if (todos.isEmpty) return;

    await db.writeTxn(() async {
      final parentIds = todos.map((todo) => todo.id).toList();
      final existingParents = await db.todoIsars.getAll(parentIds);
      final existingById = {
        for (final parent in existingParents.whereType<TodoIsar>())
          parent.id: parent,
      };

      final parentsToPut = <TodoIsar>[];
      final subtasksToPut = <TodoIsar>[];
      final subtasksToDelete = <Id>[];
      final subtaskIdsByParent = <Id, List<Id>>{};

      for (final todo in todos) {
        final parent = TodoIsar.fromDomain(
          todo.copyWith(isSubtask: false, subTasks: const <Todo>[]),
        );
        parentsToPut.add(parent);

        final incomingSubtasks = todo.subTasks
            .map((sub) =>
                sub.copyWith(isSubtask: true, subTasks: const <Todo>[]))
            .toList();
        final incomingIds = incomingSubtasks.map((sub) => sub.id).toSet();
        subtaskIdsByParent[todo.id] =
            incomingSubtasks.map((sub) => sub.id).toList();

        for (final sub in incomingSubtasks) {
          subtasksToPut.add(TodoIsar.fromDomain(sub));
        }

        final existing = existingById[todo.id];
        if (existing != null) {
          await existing.subtasks.load();
          for (final oldSub in existing.subtasks) {
            if (!incomingIds.contains(oldSub.id)) {
              subtasksToDelete.add(oldSub.id);
            }
          }
        }
      }

      await db.todoIsars.putAll(parentsToPut);
      if (subtasksToPut.isNotEmpty) {
        await db.todoIsars.putAll(subtasksToPut);
      }
      if (subtasksToDelete.isNotEmpty) {
        await db.todoIsars.deleteAll(subtasksToDelete);
      }

      final subById = {
        for (final sub in subtasksToPut) sub.id: sub,
      };

      for (final parent in parentsToPut) {
        parent.subtasks.clear();
        final subIds = subtaskIdsByParent[parent.id] ?? const <Id>[];
        for (final subId in subIds) {
          final sub = subById[subId];
          if (sub != null) {
            parent.subtasks.add(sub);
          }
        }
        await parent.subtasks.save();
      }
    });
  }

  @override
  Future<void> updateSubTask(Todo subtask) async {
    final subTaskIsar = TodoIsar.fromDomain(subtask);

    return db.writeTxn(() => db.todoIsars.put(subTaskIsar));
  }

  @override
  Future<void> deleteSubTask(Todo subtask) async {
    final subtaskIsar = TodoIsar.fromDomain(subtask);

    return db.writeTxn(() => db.todoIsars.delete(subtaskIsar.id));
  }
}
