import 'package:isar/isar.dart';
import 'package:to_do_app/data/models/isar_todo.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';

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
    await db.writeTxn(() async {
      final existingSubTasks = await db.todoIsars.get(todo.id);
      if (existingSubTasks != null) {
        await existingSubTasks.subtasks.load();
        for (var oldsub in existingSubTasks.subtasks) {
          await db.todoIsars.delete(oldsub.id);
        }
        existingSubTasks.subtasks.clear();
      }

      final todoIsar = TodoIsar.fromDomain(todo.copyWith(isSubtask: false));
      await db.todoIsars.put(todoIsar);

      for (var sub in todo.subTasks) {
        final subIsar = TodoIsar.fromDomain(sub.copyWith(isSubtask: true));
        await db.todoIsars.put(subIsar);
        todoIsar.subtasks.add(subIsar);
      }
      await todoIsar.subtasks.save();
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
