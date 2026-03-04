import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/backup/backup_service_base.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/config/router/app_router.dart';
import 'package:to_do_app/domain/repository/folder_repository.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_search_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_view_mode_cubit.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_search_cubit.dart';

import '../../../fake_repositories.dart';

Widget _buildTestApp() {
  final noteRepository = FakeNoteRepository();
  final todoRepository = FakeTodoRepository();
  final folderRepository = FakeFolderRepository();
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<NoteRepository>.value(value: noteRepository),
      RepositoryProvider<TodoRepository>.value(value: todoRepository),
      RepositoryProvider<FolderRepository>.value(value: folderRepository),
      RepositoryProvider<BackupService?>.value(value: null),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NoteCubit(noteRepository)),
        BlocProvider(create: (_) => TodoCubit(todoRepository)),
        BlocProvider(create: (_) => FolderCubit(folderRepository)),
        BlocProvider(create: (_) => FolderFilterCubit()),
        BlocProvider(create: (_) => NoteSearchCubit(const [])),
        BlocProvider(create: (_) => NoteViewModeCubit()),
        BlocProvider(create: (_) => TodoSearchCubit(const [])),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: MaterialApp.router(routerConfig: appRouter),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.configurePrefs();
    appRouter.go('/home');
  });

  testWidgets('invalid note deeplink id shows route error page', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    appRouter.go('/note/not-a-number');
    await tester.pumpAndSettle();

    expect(find.text('Invalid Note Link'), findsOneWidget);
  });

  testWidgets('invalid todo deeplink id shows route error page', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    appRouter.go('/todo/not-a-number');
    await tester.pumpAndSettle();

    expect(find.text('Invalid Todo Link'), findsOneWidget);
  });

  testWidgets('editNote without extra shows invalid route data page', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    appRouter.go('/editNote');
    await tester.pumpAndSettle();

    expect(find.text('Invalid Note Route Data'), findsOneWidget);
  });

  testWidgets('note loader shows not found page when repository returns null', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    appRouter.go('/note/9999');
    await tester.pumpAndSettle();

    expect(find.text('Note Not Found'), findsOneWidget);
  });

  testWidgets('todo loader shows not found page when repository returns null', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    appRouter.go('/todo/9999');
    await tester.pumpAndSettle();

    expect(find.text('Todo Not Found'), findsOneWidget);
  });
}
