import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/config/theme/app_theme.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_search_cubit.dart';
import 'package:to_do_app/presentation/todos/todos_view.dart';

import 'fake_repositories.dart';

Future<void> _initPrefs() async {
  SharedPreferences.setMockInitialValues({'isDarkMode': false});
  await LocalStorage.configurePrefs();
}

Widget _buildTodosApp({
  required FakeNoteRepository noteRepo,
  required FakeTodoRepository todoRepo,
  required FakeFolderRepository folderRepo,
  required List<Todo> searchSeed,
  FolderFilter initialFilter = const FolderFilter.all(),
}) {
  final router = GoRouter(
    initialLocation: '/todos',
    routes: [
      GoRoute(
        path: '/todos',
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => NoteCubit(noteRepo)),
              BlocProvider(create: (_) => TodoCubit(todoRepo)),
              BlocProvider(create: (_) => FolderCubit(folderRepo)),
              BlocProvider(
                create: (_) {
                  final cubit = FolderFilterCubit();
                  if (initialFilter.type == FolderFilterType.inbox) {
                    cubit.setInbox();
                  } else if (initialFilter.type == FolderFilterType.custom) {
                    cubit.setCustom(initialFilter.folderId!);
                  }
                  return cubit;
                },
              ),
              BlocProvider(create: (_) => TodoSearchCubit(searchSeed)),
              BlocProvider(create: (_) => ThemeCubit()),
            ],
            child: const TodosView(),
          );
        },
      ),
      GoRoute(
        path: '/addtodo',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'none';
          return Scaffold(body: Text('add-todo:$mode'));
        },
      ),
    ],
  );

  final themeData = AppTheme(isDarkMode: false).getTheme();
  return MaterialApp.router(routerConfig: router, theme: themeData);
}

void main() {
  testWidgets('shows activation empty state and routes to create first todo',
      (tester) async {
    await _initPrefs();
    final noteRepo = FakeNoteRepository(initial: const []);
    final todoRepo = FakeTodoRepository(initial: const []);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildTodosApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No todos yet'), findsOneWidget);
    expect(find.text('Create first todo'), findsOneWidget);
    expect(find.text('Set reminder'), findsOneWidget);

    await tester.tap(find.text('Create first todo'));
    await tester.pumpAndSettle();
    expect(find.text('add-todo:none'), findsOneWidget);
  });

  testWidgets('set reminder quick action routes with reminder query',
      (tester) async {
    await _initPrefs();
    final noteRepo = FakeNoteRepository(initial: const []);
    final todoRepo = FakeTodoRepository(initial: const []);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildTodosApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: const [],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set reminder'));
    await tester.pumpAndSettle();
    expect(find.text('add-todo:reminder'), findsOneWidget);
  });

  testWidgets('shows no-results state and clear search restores list',
      (tester) async {
    await _initPrefs();
    final todos = [
      Todo(
        id: 1,
        title: 'Finish report',
        isCompleted: false,
        subTasks: const [],
        isSubtask: false,
        order: 0,
      ),
    ];
    final noteRepo = FakeNoteRepository(initial: const []);
    final todoRepo = FakeTodoRepository(initial: todos);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildTodosApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: todos,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'xyz');
    await tester.pumpAndSettle();

    expect(find.text('No matches found'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Finish report'), findsOneWidget);
  });

  testWidgets('show all folders action resets folder filter and restores list',
      (tester) async {
    await _initPrefs();
    final todos = [
      Todo(
        id: 1,
        title: 'Inbox todo',
        isCompleted: false,
        subTasks: const [],
        isSubtask: false,
        order: 0,
        folderId: null,
      ),
    ];
    final folders = [
      Folder(
        id: 9,
        name: 'Work',
        order: 0,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
    final noteRepo = FakeNoteRepository(initial: const []);
    final todoRepo = FakeTodoRepository(initial: todos);
    final folderRepo = FakeFolderRepository(initial: folders);

    await tester.pumpWidget(
      _buildTodosApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: todos,
        initialFilter: const FolderFilter.custom(9),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No matches found'), findsOneWidget);

    await tester.tap(find.text('Show all folders'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox todo'), findsOneWidget);
  });
}
