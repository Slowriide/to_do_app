import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:to_do_app/core/bootstrap/app_repositories_base.dart';
import 'package:to_do_app/data/models/isar_note.dart';
import 'package:to_do_app/data/models/isar_todo.dart';
import 'package:to_do_app/data/repository/isar_note_repository_impl.dart';
import 'package:to_do_app/data/repository/isar_todo_repository_impl.dart';

Future<AppRepositories> createAppRepositories() async {
  final dir = await getApplicationDocumentsDirectory();
  final isar =
      await Isar.open([NoteIsarSchema, TodoIsarSchema], directory: dir.path);

  return AppRepositories(
    noteRepository: IsarNoteRepositoryImpl(isar),
    todoRepository: IsarTodoRepositoryImpl(isar),
  );
}
