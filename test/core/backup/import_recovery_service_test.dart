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
  final List<String> callLog = [];

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    callLog.add('cancelAll');
  }

  @override
  Future<void> syncRemindersFromDatabase({
    required NoteRepository noteRepository,
    required TodoRepository todoRepository,
  }) async {
    syncCalls++;
    callLog.add('syncRemindersFromDatabase');
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.configurePrefs();
  });

  test('startup stale marker branch performs soft recovery and clears marker',
      () async {
    final notificationService = _SpyNotificationService();
    final recoveryService = ImportRecoveryService(
      notificationService: notificationService,
    );
    final now = DateTime(2026, 3, 3, 12, 0, 0);
    final staleStartedAt = now
        .subtract(ImportRecoveryService.staleMarkerThreshold)
        .subtract(const Duration(minutes: 1));

    await LocalStorage.markImportInProgress(
      startedAtEpochMs: staleStartedAt.millisecondsSinceEpoch,
    );
    expect(LocalStorage.importInProgress, isTrue);

    final result = await recoverOrSyncRemindersOnStartup(
      noteRepository: FakeNoteRepository(),
      todoRepository: FakeTodoRepository(),
      notificationService: notificationService,
      importRecoveryService: recoveryService,
      now: now,
    );

    expect(result, ImportRecoveryResult.staleCleared);
    expect(notificationService.cancelAllCalls, 0);
    expect(notificationService.syncCalls, 1);
    expect(LocalStorage.importInProgress, isFalse);
    expect(LocalStorage.importStartedAtEpochMs, isNull);
  });

  test('recent marker triggers recovery and then clears marker', () async {
    final notificationService = _SpyNotificationService();
    final recoveryService = ImportRecoveryService(
      notificationService: notificationService,
    );
    final now = DateTime(2026, 3, 3, 12, 0, 0);
    final recentStartedAt = now.subtract(const Duration(minutes: 5));

    await LocalStorage.markImportInProgress(
      startedAtEpochMs: recentStartedAt.millisecondsSinceEpoch,
    );
    expect(LocalStorage.importInProgress, isTrue);
    expect(LocalStorage.importStartedAtEpochMs, isNotNull);

    final result = await recoveryService.recoverIfNeeded(
      noteRepository: FakeNoteRepository(),
      todoRepository: FakeTodoRepository(),
      now: now,
    );

    expect(result, ImportRecoveryResult.recovered);
    expect(notificationService.cancelAllCalls, 1);
    expect(notificationService.syncCalls, 1);
    expect(LocalStorage.importInProgress, isFalse);
    expect(LocalStorage.importStartedAtEpochMs, isNull);
  });

  test('startup with no marker performs cancelAll then normal sync', () async {
    final notificationService = _SpyNotificationService();
    final recoveryService = ImportRecoveryService(
      notificationService: notificationService,
    );

    expect(LocalStorage.importInProgress, isFalse);
    final result = await recoverOrSyncRemindersOnStartup(
      noteRepository: FakeNoteRepository(),
      todoRepository: FakeTodoRepository(),
      notificationService: notificationService,
      importRecoveryService: recoveryService,
    );

    expect(result, ImportRecoveryResult.none);
    expect(notificationService.cancelAllCalls, 1);
    expect(notificationService.syncCalls, 1);
    expect(
      notificationService.callLog,
      ['cancelAll', 'syncRemindersFromDatabase'],
    );
    expect(LocalStorage.importInProgress, isFalse);
  });

  test(
      'missing timestamp is treated as staleCleared with soft recovery on startup',
      () async {
    final notificationService = _SpyNotificationService();
    final recoveryService = ImportRecoveryService(
      notificationService: notificationService,
    );

    await LocalStorage.markImportInProgress(
      startedAtEpochMs: DateTime(2026, 3, 4, 10, 0, 0).millisecondsSinceEpoch,
    );
    await LocalStorage.prefs.remove('importStartedAtEpochMs');
    expect(LocalStorage.importInProgress, isTrue);
    expect(LocalStorage.importStartedAtEpochMs, isNull);

    final result = await recoverOrSyncRemindersOnStartup(
      noteRepository: FakeNoteRepository(),
      todoRepository: FakeTodoRepository(),
      notificationService: notificationService,
      importRecoveryService: recoveryService,
      now: DateTime(2026, 3, 4, 12, 0, 0),
    );

    expect(result, ImportRecoveryResult.staleCleared);
    expect(notificationService.cancelAllCalls, 0);
    expect(notificationService.syncCalls, 1);
    expect(LocalStorage.importInProgress, isFalse);
    expect(LocalStorage.importStartedAtEpochMs, isNull);
  });
}
