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

  test('stale import marker is auto-cleared without recovery actions', () async {
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

    final result = await recoveryService.recoverIfNeeded(
      noteRepository: FakeNoteRepository(),
      todoRepository: FakeTodoRepository(),
      now: now,
    );

    expect(result, ImportRecoveryResult.staleCleared);
    expect(notificationService.cancelAllCalls, 0);
    expect(notificationService.syncCalls, 0);
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

  test('startup with no marker skips cancelAll and performs normal sync only', () async {
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
    expect(notificationService.cancelAllCalls, 0);
    expect(notificationService.syncCalls, 1);
    expect(LocalStorage.importInProgress, isFalse);
  });
}
