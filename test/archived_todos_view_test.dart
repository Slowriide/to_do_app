import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/config/theme/app_theme.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_search_cubit.dart';
import 'package:to_do_app/presentation/todos/archived_todo_page.dart';

import 'fake_repositories.dart';

Future<void> _initPrefs() async {
  SharedPreferences.setMockInitialValues({'isDarkMode': false});
  await LocalStorage.configurePrefs();
}

Widget _buildArchivedTodosApp({
  required FakeNoteRepository noteRepo,
  required FakeTodoRepository todoRepo,
  required FakeFolderRepository folderRepo,
  required List<Todo> searchSeed,
}) {
  final router = GoRouter(
    initialLocation: '/archived-todos',
    routes: [
      GoRoute(
        path: '/archived-todos',
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => NoteCubit(noteRepo)),
              BlocProvider(create: (_) => TodoCubit(todoRepo)),
              BlocProvider(create: (_) => FolderCubit(folderRepo)),
              BlocProvider(create: (_) => FolderFilterCubit()),
              BlocProvider(create: (_) => TodoSearchCubit(searchSeed)),
              BlocProvider(create: (_) => ThemeCubit()),
            ],
            child: const ArchivedTodoPage(),
          );
        },
      ),
      GoRoute(
        path: '/todos',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );

  final themeData = AppTheme(isDarkMode: false).getTheme();
  return MaterialApp.router(routerConfig: router, theme: themeData);
}

void main() {
  testWidgets('archived route renders archived todos only', (tester) async {
    await _initPrefs();
    final todos = [
      Todo(
        id: 1,
        title: 'Archived todo',
        isCompleted: false,
        subTasks: const [],
        isSubtask: false,
        order: 0,
        isArchived: true,
      ),
      Todo(
        id: 2,
        title: 'Active todo',
        isCompleted: false,
        subTasks: const [],
        isSubtask: false,
        order: 1,
      ),
    ];
    final noteRepo = FakeNoteRepository(initial: const []);
    final todoRepo = FakeTodoRepository(initial: todos);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildArchivedTodosApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: todos,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Archived todo'), findsOneWidget);
    expect(find.text('Active todo'), findsNothing);
  });

  testWidgets('restore action removes todo from archived list', (tester) async {
    await _initPrefs();
    final todos = [
      Todo(
        id: 1,
        title: 'Archived todo',
        isCompleted: false,
        subTasks: const [],
        isSubtask: false,
        order: 0,
        isArchived: true,
      ),
    ];
    final noteRepo = FakeNoteRepository(initial: const []);
    final todoRepo = FakeTodoRepository(initial: todos);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildArchivedTodosApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: todos,
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Archived todo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.unarchive_outlined));
    await tester.pumpAndSettle();

    expect(find.text('No archived todos'), findsOneWidget);
  });

}
