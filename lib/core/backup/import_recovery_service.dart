import 'package:flutter/foundation.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';

class ImportRecoveryService {
  static const Duration staleMarkerThreshold = Duration(minutes: 30);

  final NotificationService notificationService;

  ImportRecoveryService({
    NotificationService? notificationService,
  }) : notificationService = notificationService ?? NotificationService();

  Future<void> markImportStarted() async {
    await LocalStorage.markImportInProgress();
  }

  Future<void> clearImportMarker() async {
    await LocalStorage.clearImportInProgress();
  }

  Future<bool> recoverIfNeeded({
    required NoteRepository noteRepository,
    required TodoRepository todoRepository,
    DateTime? now,
  }) async {
    if (!LocalStorage.importInProgress) {
      return false;
    }
    final startedAtEpochMs = LocalStorage.importStartedAtEpochMs;
    final currentTime = now ?? DateTime.now();
    if (startedAtEpochMs != null) {
      final startedAt = DateTime.fromMillisecondsSinceEpoch(startedAtEpochMs);
      final age = currentTime.difference(startedAt);
      if (age > staleMarkerThreshold) {
        debugPrint(
          'Import recovery: cleared stale import marker '
          '(age=${age.inMinutes}m > ${staleMarkerThreshold.inMinutes}m).',
        );
        await clearImportMarker();
        return false;
      }
    }

    await notificationService.cancelAll();
    await notificationService.syncRemindersFromDatabase(
      noteRepository: noteRepository,
      todoRepository: todoRepository,
    );
    await clearImportMarker();
    return true;
  }
}
