import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';

class AppRepositories {
  final NoteRepository noteRepository;
  final TodoRepository todoRepository;

  const AppRepositories({
    required this.noteRepository,
    required this.todoRepository,
  });
}
