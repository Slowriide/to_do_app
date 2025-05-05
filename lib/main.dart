import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:to_do_app/core/config/router/app_router.dart';
import 'package:to_do_app/core/config/theme/app_theme.dart';
import 'package:to_do_app/data/models/isar_note.dart';
import 'package:to_do_app/data/models/isar_todo.dart';
import 'package:to_do_app/data/repository/isar_note_repository_impl.dart';
import 'package:to_do_app/data/repository/isar_todo_repository_impl.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:to_do_app/presentation/cubits/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/todo_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

//get dir path for storage data
  final dir = await getApplicationDocumentsDirectory();

  //open db
  final isar =
      await Isar.open([NoteIsarSchema, TodoIsarSchema], directory: dir.path);

  //init repo
  final isarNoteRepo = IsarNoteRepositoryImpl(isar);
  final isarTodosRepo = IsarTodoRepositoryImpl(isar);

  runApp(MyApp(
    noteRepo: isarNoteRepo,
    todoRepo: isarTodosRepo,
  ));
}

class MyApp extends StatelessWidget {
  //db injection
  final NoteRepository noteRepo;
  final TodoRepository todoRepo;
  const MyApp({super.key, required this.noteRepo, required this.todoRepo});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: noteRepo),
        RepositoryProvider.value(value: todoRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => NoteCubit(noteRepo),
          ),
          BlocProvider(
            create: (context) => TodoCubit(todoRepo),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: appRouter,
          theme: AppTheme().getTheme(),
          title: 'ToDo App',
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
