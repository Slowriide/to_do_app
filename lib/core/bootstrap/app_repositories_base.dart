import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:to_do_app/domain/repository/folder_repository.dart';

class AppRepositories {
  final NoteRepository noteRepository;
  final TodoRepository todoRepository;
  final FolderRepository folderRepository;

  const AppRepositories({
    required this.noteRepository,
    required this.todoRepository,
    required this.folderRepository,
  });
}
