import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/backup/backup_service_base.dart';
import 'package:to_do_app/core/backup/backup_service_io.dart';
import 'package:to_do_app/core/backup/import_recovery_service.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/data/models/isar_folder.dart';
import 'package:to_do_app/data/models/isar_note.dart';
import 'package:to_do_app/data/models/isar_todo.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:to_do_app/main.dart';

import '../../fake_repositories.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String documentsPath;

  _FakePathProviderPlatform(this.documentsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

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

Future<File> _writeBackupZip(
  Directory tempDir,
  Map<String, dynamic> payload,
) async {
  final archive = Archive();
  final bytes = utf8.encode(jsonEncode(payload));
  archive.addFile(ArchiveFile('backup.json', bytes.length, bytes));
  final encoded = ZipEncoder().encode(archive);

  final zipFile =
      File('${tempDir.path}${Platform.pathSeparator}backup_marker.zip');
  await zipFile.writeAsBytes(encoded, flush: true);
  return zipFile;
}

Map<String, dynamic> _validReplacePayload() {
  return <String, dynamic>{
    'metadata': <String, dynamic>{
      'schemaVersion': 2,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'appVersion': '1.0.0+1',
      'platform': 'test',
      'includeMedia': false,
    },
    'folders': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 10,
        'name': 'import-folder',
        'parentId': null,
        'order': 0,
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      },
    ],
    'notes': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 20,
        'title': 'import-note',
        'titleRichTextDeltaJson': null,
        'text': 'import-note-body',
        'richTextDeltaJson': null,
        'isCompleted': false,
        'reminder': null,
        'isPinned': false,
        'isArchived': false,
        'order': 0,
        'folderIds': <int>[10],
      },
    ],
    'todos': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 30,
        'title': 'import-todo',
        'titleRichTextDeltaJson': null,
        'isCompleted': false,
        'isSubtask': false,
        'order': 0,
        'reminder': null,
        'isPinned': false,
        'isArchived': false,
        'folderIds': <int>[10],
        'subTasks': const <Map<String, dynamic>>[],
      },
    ],
  };
}

Map<String, dynamic> _invalidSchemaPayload() {
  final payload = _validReplacePayload();
  (payload['metadata'] as Map<String, dynamic>)['schemaVersion'] = 999;
  return payload;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var isarCoreReady = false;
  late Directory tempDir;
  late Isar isar;
  var isarOpened = false;

  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
      isarCoreReady = true;
    } catch (e) {
      // ignore: avoid_print
      print('Skipping import marker lifecycle tests: $e');
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.configurePrefs();
    if (!isarCoreReady) return;
    tempDir = await Directory.systemTemp.createTemp('import_marker_lifecycle_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    isar = await Isar.open(
      <CollectionSchema>[NoteIsarSchema, TodoIsarSchema, FolderIsarSchema],
      directory: tempDir.path,
      name: 'test_${DateTime.now().microsecondsSinceEpoch}',
    );
    isarOpened = true;
  });

  tearDown(() async {
    if (!isarCoreReady || !isarOpened) return;
    await isar.close(deleteFromDisk: true);
    isarOpened = false;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'writeTxn failure keeps marker set, next startup recovery clears it',
    () async {
      if (!isarCoreReady) return;
      final zip = await _writeBackupZip(tempDir, _validReplacePayload());
      final notificationService = _SpyNotificationService();
      final recoveryService =
          ImportRecoveryService(notificationService: notificationService);
      final service = BackupServiceImpl(
        isar,
        importHooks: BackupImportHooks(
          onCheckpoint: (checkpoint) {
            if (checkpoint == BackupImportCheckpoint.afterReplaceClear) {
              throw StateError('forced-after-clear');
            }
          },
        ),
      );

      await recoveryService.markImportStarted();
      expect(LocalStorage.importInProgress, isTrue);

      await expectLater(
        () => service.importBackup(zip, mode: ImportMode.replace),
        throwsA(isA<BackupImportException>()),
      );
      expect(LocalStorage.importInProgress, isTrue);

      final recoveryResult = await recoverOrSyncRemindersOnStartup(
        noteRepository: FakeNoteRepository(),
        todoRepository: FakeTodoRepository(),
        notificationService: notificationService,
        importRecoveryService: recoveryService,
      );

      expect(recoveryResult, ImportRecoveryResult.recovered);
      expect(notificationService.cancelAllCalls, 1);
      expect(notificationService.syncCalls, 1);
      expect(LocalStorage.importInProgress, isFalse);
    },
  );

  test(
    'preflight schema failure keeps marker set, then startup recovery clears it',
    () async {
      if (!isarCoreReady) return;
      final zip = await _writeBackupZip(tempDir, _invalidSchemaPayload());
      final notificationService = _SpyNotificationService();
      final recoveryService =
          ImportRecoveryService(notificationService: notificationService);
      final service = BackupServiceImpl(isar);

      await recoveryService.markImportStarted();
      expect(LocalStorage.importInProgress, isTrue);

      await expectLater(
        () => service.importBackup(zip, mode: ImportMode.replace),
        throwsA(isA<BackupSchemaException>()),
      );
      expect(LocalStorage.importInProgress, isTrue);

      final recoveryResult = await recoverOrSyncRemindersOnStartup(
        noteRepository: FakeNoteRepository(),
        todoRepository: FakeTodoRepository(),
        notificationService: notificationService,
        importRecoveryService: recoveryService,
      );

      expect(recoveryResult, ImportRecoveryResult.recovered);
      expect(notificationService.cancelAllCalls, 1);
      expect(notificationService.syncCalls, 1);
      expect(LocalStorage.importInProgress, isFalse);
    },
  );
}
