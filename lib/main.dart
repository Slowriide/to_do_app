import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/config/router/app_router.dart';
import 'package:to_do_app/core/config/theme/app_theme.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/data/models/isar_note.dart';
import 'package:to_do_app/data/models/isar_todo.dart';
import 'package:to_do_app/data/repository/isar_note_repository_impl.dart';
import 'package:to_do_app/data/repository/isar_todo_repository_impl.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:to_do_app/presentation/cubits/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/note_search_cubit.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';
import 'package:to_do_app/presentation/cubits/todo_cubit.dart';
import 'package:to_do_app/presentation/cubits/todo_search_cubit.dart';

/// Entry point of the application.
///
/// Initializes local storage, notification service, and database,
/// then injects repositories and sets up Bloc providers for state management.
///
/// Also handles theme switching and routing configuration.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local preferences storage.
  await LocalStorage.configurePrefs();

  // Initialize notification service.
  await NotificationService().init();

  // Get the application documents directory for Isar database storage.
  final dir = await getApplicationDocumentsDirectory();

  // Open the Isar database with note and todo schemas.
  final isar =
      await Isar.open([NoteIsarSchema, TodoIsarSchema], directory: dir.path);

  // Initialize repositories with the Isar database instance.
  final isarNoteRepo = IsarNoteRepositoryImpl(isar);
  final isarTodosRepo = IsarTodoRepositoryImpl(isar);

  // Run the app with injected repositories.
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
          BlocProvider(create: (context) => NoteCubit(noteRepo)..loadNotes()),
          BlocProvider(create: (context) => TodoCubit(todoRepo)..loadTodos()),
          BlocProvider(create: (context) => NoteSearchCubit([])),
          BlocProvider(create: (context) => TodoSearchCubit([])),
          BlocProvider(create: (context) => ThemeCubit()),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(builder: (context, state) {
          final themeData = AppTheme(isDarkMode: state.isDarkmode).getTheme();

          return AnimatedTheme(
            data: themeData,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: MaterialApp.router(
              routerConfig: appRouter,
              theme: themeData,
              title: 'ToDo App',
              debugShowCheckedModeBanner: false,
            ),
          );
        }),
      ),
    );
  }
}
