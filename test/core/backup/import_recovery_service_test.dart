import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/backup/import_recovery_service.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:to_do_app/main.dart';

import '../../fake_repositories.dart';

class _SpyNotificationService extends NotificationService {
  int cancelAllCalls = 0;
  int syncCalls = 0;

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }

  @override
  Future<void> syncRemindersFromDatabase({
    required NoteRepository noteRepository,
    required TodoRepository todoRepository,
  }) async {
    syncCalls++;
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.configurePrefs();
  });

  test('startup recovery runs when import marker is set and clears marker', () async {
    final notificationService = _SpyNotificationService();
    final recoveryService = ImportRecoveryService(
      notificationService: notificationService,
    );

    await recoveryService.markImportStarted();
    expect(LocalStorage.importInProgress, isTrue);
    expect(LocalStorage.importStartedAtEpochMs, isNotNull);

    final didRecover = await recoverOrSyncRemindersOnStartup(
      noteRepository: FakeNoteRepository(),
      todoRepository: FakeTodoRepository(),
      notificationService: notificationService,
      importRecoveryService: recoveryService,
    );

    expect(didRecover, isTrue);
    expect(notificationService.cancelAllCalls, 1);
    expect(notificationService.syncCalls, 1);
    expect(LocalStorage.importInProgress, isFalse);
    expect(LocalStorage.importStartedAtEpochMs, isNull);
  });
}
