import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/config/theme/app_theme.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_search_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_view_mode_cubit.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/notes/archived_note_page.dart';

import 'fake_repositories.dart';

Future<void> _initPrefs() async {
  SharedPreferences.setMockInitialValues({'isDarkMode': false});
  await LocalStorage.configurePrefs();
}

Widget _buildArchivedApp({
  required FakeNoteRepository noteRepo,
  required FakeTodoRepository todoRepo,
  required FakeFolderRepository folderRepo,
  required List<Note> searchSeed,
}) {
  final router = GoRouter(
    initialLocation: '/archived-notes',
    routes: [
      GoRoute(
        path: '/archived-notes',
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => NoteCubit(noteRepo)),
              BlocProvider(create: (_) => TodoCubit(todoRepo)),
              BlocProvider(create: (_) => FolderCubit(folderRepo)),
              BlocProvider(create: (_) => FolderFilterCubit()),
              BlocProvider(create: (_) => NoteSearchCubit(searchSeed)),
              BlocProvider(create: (_) => NoteViewModeCubit()),
              BlocProvider(create: (_) => ThemeCubit()),
            ],
            child: const ArchivedNotePage(),
          );
        },
      ),
    ],
  );

  final themeData = AppTheme(isDarkMode: false).getTheme();
  return MaterialApp.router(routerConfig: router, theme: themeData);
}

void main() {
  testWidgets('archived route renders archived notes only', (tester) async {
    await _initPrefs();
    final notes = [
      Note(id: 1, title: 'Archived note', text: 'a', isArchived: true),
      Note(id: 2, title: 'Active note', text: 'b'),
    ];
    final noteRepo = FakeNoteRepository(initial: notes);
    final todoRepo = FakeTodoRepository(initial: const []);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildArchivedApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: notes,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Archived note'), findsOneWidget);
    expect(find.text('Active note'), findsNothing);
  });

  testWidgets('restore action removes note from archived list', (tester) async {
    await _initPrefs();
    final notes = [
      Note(id: 1, title: 'Archived note', text: 'a', isArchived: true),
    ];
    final noteRepo = FakeNoteRepository(initial: notes);
    final todoRepo = FakeTodoRepository(initial: const []);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildArchivedApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: notes,
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Archived note'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.unarchive_outlined));
    await tester.pumpAndSettle();

    expect(find.text('No archived notes'), findsOneWidget);
  });

  testWidgets('delete action permanently removes archived note',
      (tester) async {
    await _initPrefs();
    final notes = [
      Note(id: 1, title: 'Archived note', text: 'a', isArchived: true),
    ];
    final noteRepo = FakeNoteRepository(initial: notes);
    final todoRepo = FakeTodoRepository(initial: const []);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildArchivedApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: notes,
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Archived note'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No archived notes'), findsOneWidget);
  });
}
