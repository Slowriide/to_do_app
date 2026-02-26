import 'package:to_do_app/core/bootstrap/app_repositories_base.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/domain/repository/folder_repository.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';

class InMemoryNoteRepository implements NoteRepository {
  final List<Note> _notes = [];

  @override
  Future<void> addNote(Note newNote) async {
    _notes.removeWhere((n) => n.id == newNote.id);
    _notes.add(newNote);
  }

  @override
  Future<void> deleteNote(Note note) async {
    _notes.removeWhere((n) => n.id == note.id);
  }

  @override
  Future<List<Note>> getNotes() async {
    return List<Note>.from(_notes);
  }

  @override
  Future<void> updateNote(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
      return;
    }
    _notes.add(note);
  }

  @override
  Future<void> updateNotes(List<Note> notes) async {
    final byId = {for (final note in notes) note.id: note};
    for (var i = 0; i < _notes.length; i++) {
      final updated = byId[_notes[i].id];
      if (updated != null) {
        _notes[i] = updated;
      }
    }
    for (final note in notes) {
      if (_notes.every((existing) => existing.id != note.id)) {
        _notes.add(note);
      }
    }
  }
}

class InMemoryTodoRepository implements TodoRepository {
  final List<Todo> _todos = [];

  @override
  Future<void> addTodo(Todo newTodo) async {
    _todos.removeWhere((t) => t.id == newTodo.id);
    _todos.add(newTodo.copyWith(isSubtask: false));
  }

  @override
  Future<void> deleteTodo(Todo todo) async {
    _todos.removeWhere((t) => t.id == todo.id);
  }

  @override
  Future<List<Todo>> getTodos() async {
    return List<Todo>.from(_todos);
  }

  @override
  Future<void> updateTodo(Todo todo) async {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index >= 0) {
      _todos[index] = todo;
      return;
    }
    _todos.add(todo);
  }

  @override
  Future<void> updateTodos(List<Todo> todos) async {
    final byId = {for (final todo in todos) todo.id: todo};
    for (var i = 0; i < _todos.length; i++) {
      final updated = byId[_todos[i].id];
      if (updated != null) {
        _todos[i] = updated;
      }
    }
    for (final todo in todos) {
      if (_todos.every((existing) => existing.id != todo.id)) {
        _todos.add(todo);
      }
    }
  }

  @override
  Future<void> addSubTask(Todo subtask, int todoId) async {
    final index = _todos.indexWhere((t) => t.id == todoId);
    if (index < 0) {
      throw Exception('Todo with id $todoId not found.');
    }

    final todo = _todos[index];
    final subtasks = List<Todo>.from(todo.subTasks)
      ..removeWhere((s) => s.id == subtask.id)
      ..add(subtask.copyWith(isSubtask: true));
    _todos[index] = todo.copyWith(subTasks: subtasks);
  }

  @override
  Future<void> updateSubTask(Todo subtask) async {
    for (var i = 0; i < _todos.length; i++) {
      final todo = _todos[i];
      final subIndex = todo.subTasks.indexWhere((s) => s.id == subtask.id);
      if (subIndex >= 0) {
        final subtasks = List<Todo>.from(todo.subTasks);
        subtasks[subIndex] = subtask.copyWith(isSubtask: true);
        _todos[i] = todo.copyWith(subTasks: subtasks);
        return;
      }
    }
  }

  @override
  Future<void> deleteSubTask(Todo subtask) async {
    for (var i = 0; i < _todos.length; i++) {
      final todo = _todos[i];
      final subtasks = List<Todo>.from(todo.subTasks)
        ..removeWhere((s) => s.id == subtask.id);
      if (subtasks.length != todo.subTasks.length) {
        _todos[i] = todo.copyWith(subTasks: subtasks);
        return;
      }
    }
  }
}

class InMemoryFolderRepository implements FolderRepository {
  final List<Folder> _folders = [];

  @override
  Future<void> addFolder(Folder folder) async {
    _folders.removeWhere((f) => f.id == folder.id);
    _folders.add(folder);
  }

  @override
  Future<void> deleteFolder(int folderId) async {
    _folders.removeWhere((f) => f.id == folderId);
  }

  @override
  Future<void> deleteFolderSubtree(int folderId) async {
    final descendants = await getDescendantIds(folderId);
    final all = <int>{folderId, ...descendants};
    _folders.removeWhere((f) => all.contains(f.id));
  }

  @override
  Future<List<Folder>> getFolders() async {
    return List<Folder>.from(_folders);
  }

  @override
  Future<Set<int>> getDescendantIds(int folderId) async {
    final result = <int>{};
    final queue = <int>[folderId];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final folder in _folders.where((f) => f.parentId == current)) {
        if (result.add(folder.id)) {
          queue.add(folder.id);
        }
      }
    }
    return result;
  }

  @override
  Future<void> updateFolder(Folder folder) async {
    final index = _folders.indexWhere((f) => f.id == folder.id);
    if (index >= 0) {
      _folders[index] = folder;
      return;
    }
    _folders.add(folder);
  }

  @override
  Future<void> moveFolder({
    required int folderId,
    required int? newParentId,
    required int newOrder,
  }) async {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index < 0) return;
    _folders[index] = _folders[index].copyWith(
      parentId: newParentId,
      order: newOrder,
    );
  }
}

Future<AppRepositories> createAppRepositories() async {
  return AppRepositories(
    noteRepository: InMemoryNoteRepository(),
    todoRepository: InMemoryTodoRepository(),
    folderRepository: InMemoryFolderRepository(),
  );
}
