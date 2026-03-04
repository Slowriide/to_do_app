import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/core/backup/backup_service_base.dart';
import 'package:to_do_app/core/config/router/app_router.dart';
import 'package:to_do_app/domain/repository/folder_repository.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';

import '../../../fake_repositories.dart';

Widget _buildTestApp() {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<NoteRepository>(create: (_) => FakeNoteRepository()),
      RepositoryProvider<TodoRepository>(create: (_) => FakeTodoRepository()),
      RepositoryProvider<FolderRepository>(create: (_) => FakeFolderRepository()),
      RepositoryProvider<BackupService?>.value(value: null),
    ],
    child: MaterialApp.router(routerConfig: appRouter),
  );
}

void main() {
  setUp(() {
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
}
