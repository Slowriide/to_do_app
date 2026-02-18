import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/core/bootstrap/app_repositories.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/config/router/app_router.dart';
import 'package:to_do_app/core/config/theme/app_theme.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:to_do_app/domain/repository/folder_repository.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_search_cubit.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_search_cubit.dart';

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

  final repositories = await createAppRepositories();

  // Run the app with injected repositories.
  runApp(MyApp(
    noteRepo: repositories.noteRepository,
    todoRepo: repositories.todoRepository,
    folderRepo: repositories.folderRepository,
  ));
}

class MyApp extends StatelessWidget {
  //db injection
  final NoteRepository noteRepo;
  final TodoRepository todoRepo;
  final FolderRepository folderRepo;
  const MyApp({
    super.key,
    required this.noteRepo,
    required this.todoRepo,
    required this.folderRepo,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: noteRepo),
        RepositoryProvider.value(value: todoRepo),
        RepositoryProvider.value(value: folderRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => NoteCubit(noteRepo)),
          BlocProvider(create: (context) => TodoCubit(todoRepo)),
          BlocProvider(create: (context) => FolderCubit(folderRepo)),
          BlocProvider(create: (context) => FolderFilterCubit()),
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
