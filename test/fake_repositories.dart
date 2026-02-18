import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/domain/repository/folder_repository.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({List<Note>? initial}) : _notes = [...?initial];

  List<Note> _notes;

  @override
  Future<void> addNote(Note newNote) async {
    _notes.removeWhere((note) => note.id == newNote.id);
    _notes.add(newNote);
  }

  @override
  Future<void> deleteNote(Note note) async {
    _notes.removeWhere((item) => item.id == note.id);
  }

  @override
  Future<List<Note>> getNotes() async => List<Note>.from(_notes);

  @override
  Future<void> updateNote(Note note) async {
    final index = _notes.indexWhere((item) => item.id == note.id);
    if (index < 0) {
      _notes.add(note);
      return;
    }
    _notes[index] = note;
  }

  @override
  Future<void> updateNotes(List<Note> notes) async {
    for (final note in notes) {
      await updateNote(note);
    }
  }
}

class FakeTodoRepository implements TodoRepository {
  FakeTodoRepository({List<Todo>? initial}) : _todos = [...?initial];

  List<Todo> _todos;

  @override
  Future<void> addSubTask(Todo subtask, int todoId) async {
    final index = _todos.indexWhere((todo) => todo.id == todoId);
    if (index < 0) {
      throw Exception('Todo with id $todoId not found.');
    }
    final todo = _todos[index];
    _todos[index] = todo.copyWith(subTasks: [...todo.subTasks, subtask]);
  }

  @override
  Future<void> addTodo(Todo newTodo) async {
    _todos.removeWhere((todo) => todo.id == newTodo.id);
    _todos.add(newTodo);
  }

  @override
  Future<void> deleteSubTask(Todo subtask) async {
    _todos = _todos
        .map((todo) => todo.copyWith(
              subTasks:
                  todo.subTasks.where((task) => task.id != subtask.id).toList(),
            ))
        .toList();
  }

  @override
  Future<void> deleteTodo(Todo todo) async {
    _todos.removeWhere((item) => item.id == todo.id);
  }

  @override
  Future<List<Todo>> getTodos() async => List<Todo>.from(_todos);

  @override
  Future<void> updateSubTask(Todo subtask) async {
    _todos = _todos.map((todo) {
      final subtasks = todo.subTasks.map((task) {
        if (task.id == subtask.id) return subtask;
        return task;
      }).toList();
      return todo.copyWith(subTasks: subtasks);
    }).toList();
  }

  @override
  Future<void> updateTodo(Todo todo) async {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index < 0) {
      _todos.add(todo);
      return;
    }
    _todos[index] = todo;
  }

  @override
  Future<void> updateTodos(List<Todo> todos) async {
    for (final todo in todos) {
      await updateTodo(todo);
    }
  }
}

class FakeFolderRepository implements FolderRepository {
  FakeFolderRepository({List<Folder>? initial}) : _folders = [...?initial];

  List<Folder> _folders;

  @override
  Future<void> addFolder(Folder folder) async {
    _folders.removeWhere((item) => item.id == folder.id);
    _folders.add(folder);
  }

  @override
  Future<void> deleteFolder(int folderId) async {
    _folders.removeWhere((folder) => folder.id == folderId);
  }

  @override
  Future<List<Folder>> getFolders() async => List<Folder>.from(_folders);

  @override
  Future<void> updateFolder(Folder folder) async {
    final index = _folders.indexWhere((item) => item.id == folder.id);
    if (index < 0) {
      _folders.add(folder);
      return;
    }
    _folders[index] = folder;
  }
}
