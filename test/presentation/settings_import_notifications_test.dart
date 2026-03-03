import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/core/backup/backup_service_base.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:to_do_app/presentation/settings_screen.dart';

import '../fake_repositories.dart';

class _SpyNotificationService extends NotificationService {
  final List<String> calls = [];

  @override
  Future<void> cancelAll() async {
    calls.add('cancelAll');
  }

  @override
  Future<void> syncRemindersFromDatabase({
    required NoteRepository noteRepository,
    required TodoRepository todoRepository,
  }) async {
    calls.add('syncRemindersFromDatabase');
  }
}

void main() {
  test('replace-import clears stale notifications before resync', () async {
    final service = _SpyNotificationService();

    await resyncNotificationsAfterImport(
      mode: ImportMode.replace,
      notificationService: service,
      noteRepository: FakeNoteRepository(),
      todoRepository: FakeTodoRepository(),
    );

    expect(
      service.calls,
      ['cancelAll', 'syncRemindersFromDatabase'],
    );
  });
}
