import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:to_do_app/core/backup/backup_service_base.dart';
import 'package:to_do_app/core/backup/backup_service_io.dart';
import 'package:to_do_app/data/models/isar_folder.dart';
import 'package:to_do_app/data/models/isar_note.dart';
import 'package:to_do_app/data/models/isar_todo.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String documentsPath;

  _FakePathProviderPlatform(this.documentsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

Future<File> _writeBackupZip(
  Directory tempDir,
  Map<String, dynamic> payload,
) async {
  final archive = Archive();
  final bytes = utf8.encode(jsonEncode(payload));
  archive.addFile(ArchiveFile('backup.json', bytes.length, bytes));
  final encoded = ZipEncoder().encode(archive);

  final zipFile = File('${tempDir.path}${Platform.pathSeparator}backup.zip');
  await zipFile.writeAsBytes(encoded, flush: true);
  return zipFile;
}

Map<String, dynamic> _buildMergePayload() {
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
        'id': 1,
        'name': 'import-parent',
        'parentId': null,
        'order': 0,
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      },
      <String, dynamic>{
        'id': 2,
        'name': 'import-child',
        'parentId': 1,
        'order': 1,
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      },
      <String, dynamic>{
        'id': 10,
        'name': 'import-orphan',
        'parentId': 999,
        'order': 2,
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      },
    ],
    'notes': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'title': 'import-note',
        'titleRichTextDeltaJson': null,
        'text': 'import-note-body',
        'richTextDeltaJson': null,
        'isCompleted': false,
        'reminder': null,
        'isPinned': false,
        'isArchived': false,
        'order': 0,
        'folderIds': <int>[1, 2, 10, 9999],
      },
    ],
    'todos': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'title': 'import-root',
        'titleRichTextDeltaJson': null,
        'isCompleted': false,
        'isSubtask': false,
        'order': 0,
        'reminder': null,
        'isPinned': false,
        'isArchived': false,
        'folderIds': <int>[1, 2, 9999],
        'subTasks': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 3,
            'title': 'import-child-task',
            'titleRichTextDeltaJson': null,
            'isCompleted': false,
            'isSubtask': true,
            'order': 0,
            'reminder': null,
            'isPinned': false,
            'isArchived': false,
            'folderIds': <int>[2, 9999],
            'subTasks': const <Map<String, dynamic>>[],
          },
        ],
      },
    ],
  };
}

Future<void> _seedExisting(Isar db) async {
  await db.writeTxn(() async {
    await db.folderIsars.put(
      FolderIsar()
        ..id = 1
        ..name = 'local-folder'
        ..nameNormalized = 'local-folder'
        ..parentId = null
        ..order = 0
        ..createdAt = DateTime.utc(2025, 1, 1),
    );

    await db.noteIsars.put(
      NoteIsar()
        ..id = 1
        ..title = 'local-note'
        ..text = 'local-note-body'
        ..isCompleted = false
        ..isPinned = false
        ..isArchived = false
        ..order = 0
        ..folderIds = <int>[1],
    );

    await db.todoIsars.putAll(<TodoIsar>[
      TodoIsar()
        ..id = 1
        ..title = 'local-root'
        ..isCompleted = false
        ..isSubtask = false
        ..order = 0
        ..isPinned = false
        ..isArchived = false
        ..folderIds = <int>[1],
      TodoIsar()
        ..id = 3
        ..title = 'local-conflict'
        ..isCompleted = false
        ..isSubtask = false
        ..order = 1
        ..isPinned = false
        ..isArchived = false
        ..folderIds = <int>[1],
    ]);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Isar isar;
  late BackupServiceImpl service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_merge_remap_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    isar = await Isar.open(
      <CollectionSchema>[NoteIsarSchema, TodoIsarSchema, FolderIsarSchema],
      directory: tempDir.path,
      name: 'test_${DateTime.now().microsecondsSinceEpoch}',
    );
    service = BackupServiceImpl(isar);
    await _seedExisting(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('merge import remaps colliding note/todo/folder IDs without overwrite', () async {
    final zip = await _writeBackupZip(tempDir, _buildMergePayload());

    await service.importBackup(zip, mode: ImportMode.merge);

    final localFolder = await isar.folderIsars.get(1);
    final localNote = await isar.noteIsars.get(1);
    final localTodo = await isar.todoIsars.get(1);

    expect(localFolder?.name, 'local-folder');
    expect(localNote?.title, 'local-note');
    expect(localTodo?.title, 'local-root');

    final importedNote =
        await isar.noteIsars.filter().titleEqualTo('import-note').findFirst();
    final importedRootTodo =
        await isar.todoIsars.filter().titleEqualTo('import-root').findFirst();

    expect(importedNote, isNotNull);
    expect(importedRootTodo, isNotNull);
    expect(importedNote!.id, isNot(1));
    expect(importedRootTodo!.id, isNot(1));
  });

  test('merge import preserves folder hierarchy with remapped parent IDs', () async {
    final zip = await _writeBackupZip(tempDir, _buildMergePayload());

    await service.importBackup(zip, mode: ImportMode.merge);

    final importedParent =
        await isar.folderIsars.filter().nameEqualTo('import-parent').findFirst();
    final importedChild =
        await isar.folderIsars.filter().nameEqualTo('import-child').findFirst();
    final importedOrphan =
        await isar.folderIsars.filter().nameEqualTo('import-orphan').findFirst();

    expect(importedParent, isNotNull);
    expect(importedChild, isNotNull);
    expect(importedOrphan, isNotNull);
    expect(importedChild!.parentId, importedParent!.id);
    expect(importedOrphan!.parentId, isNull);

    final importedNote =
        await isar.noteIsars.filter().titleEqualTo('import-note').findFirst();
    expect(importedNote, isNotNull);
    expect(
      importedNote!.folderIds.toSet(),
      {importedParent.id, importedChild.id, importedOrphan.id},
    );
  });

  test('merge import keeps todo subtree linked correctly after remap', () async {
    final zip = await _writeBackupZip(tempDir, _buildMergePayload());

    await service.importBackup(zip, mode: ImportMode.merge);

    final importedRoot =
        await isar.todoIsars.filter().titleEqualTo('import-root').findFirst();
    expect(importedRoot, isNotNull);

    await importedRoot!.subtasks.load();
    expect(importedRoot.subtasks.length, 1);
    final child = importedRoot.subtasks.first;
    expect(child.title, 'import-child-task');
    expect(child.id, isNot(3));

    final importedParent =
        await isar.folderIsars.filter().nameEqualTo('import-parent').findFirst();
    final importedChild =
        await isar.folderIsars.filter().nameEqualTo('import-child').findFirst();

    expect(importedRoot.folderIds.toSet(), {importedParent!.id, importedChild!.id});
    expect(child.folderIds.toSet(), {importedChild.id});
  });
}
