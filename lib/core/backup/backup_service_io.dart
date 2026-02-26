import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:to_do_app/core/backup/backup_service_base.dart';
import 'package:to_do_app/core/storage/note_sketch_storage_service.dart';
import 'package:to_do_app/data/models/isar_folder.dart';
import 'package:to_do_app/data/models/isar_note.dart';
import 'package:to_do_app/data/models/isar_todo.dart';

class BackupServiceImpl extends BackupService {
  static const int _schemaVersion = 2;

  final Isar db;
  final NoteSketchStorageService sketchStorage;

  BackupServiceImpl(
    this.db, {
    NoteSketchStorageService? sketchStorage,
  }) : sketchStorage = sketchStorage ?? createNoteSketchStorageService();

  @override
  Future<File> exportBackup({bool includeMedia = true}) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final backupsDir = Directory(_join(docs.path, 'backups'));
      if (!backupsDir.existsSync()) {
        await backupsDir.create(recursive: true);
      }

      final notes = await db.noteIsars.where().findAll();
      final folders = await db.folderIsars.where().findAll();
      final rootTodos = await db.todoIsars.filter().isSubtaskEqualTo(false).findAll();
      for (final todo in rootTodos) {
        await _loadTodoTree(todo);
      }

      final absoluteToRelative = <String, String>{};
      final noteJson = <Map<String, dynamic>>[];
      for (final note in notes) {
        noteJson.add(_noteToJson(
          note,
          absoluteToRelative: absoluteToRelative,
        ));
      }

      final folderJson = folders.map(_folderToJson).toList(growable: false);
      final todoJson = <Map<String, dynamic>>[];
      for (final todo in rootTodos) {
        todoJson.add(await _todoToJsonRecursive(todo));
      }

      final info = await PackageInfo.fromPlatform();
      final appVersion = '${info.version}+${info.buildNumber}';
      final backupPayload = <String, dynamic>{
        'metadata': <String, dynamic>{
          'schemaVersion': _schemaVersion,
          'exportedAt': DateTime.now().toUtc().toIso8601String(),
          'appVersion': appVersion,
          'platform': Platform.operatingSystem,
          'includeMedia': includeMedia,
        },
        'folders': folderJson,
        'notes': noteJson,
        'todos': todoJson,
      };

      final archive = Archive();
      final backupBytes = utf8.encode(jsonEncode(backupPayload));
      archive.addFile(ArchiveFile('backup.json', backupBytes.length, backupBytes));

      if (includeMedia && absoluteToRelative.isNotEmpty) {
        await _appendMediaFilesToArchive(
          archive: archive,
          absolutePaths: absoluteToRelative.keys,
          absoluteToRelative: absoluteToRelative,
        );
      }

      final encoded = ZipEncoder().encode(archive);

      final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.zip';
      final output = File(_join(backupsDir.path, fileName));
      await output.writeAsBytes(encoded, flush: true);
      return output;
    } on BackupExportException {
      rethrow;
    } catch (e) {
      throw BackupExportException('Failed to export backup: $e');
    }
  }

  @override
  Future<void> importBackup(File zipFile, {required ImportMode mode}) async {
    try {
      if (!await zipFile.exists()) {
        throw BackupImportException('Backup ZIP not found: ${zipFile.path}');
      }

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      final backupEntry = archive.files.firstWhere(
        (file) => file.name == 'backup.json' && file.isFile,
        orElse: () => throw BackupFormatException('ZIP does not contain backup.json'),
      );

      final backupJsonString = utf8.decode(_readArchiveFileBytes(backupEntry));
      final decoded = jsonDecode(backupJsonString);
      if (decoded is! Map<String, dynamic>) {
        throw BackupFormatException('backup.json root must be a JSON object.');
      }

      _validateBackupStructure(decoded);
      _validateSchema(decoded);

      final relativeToAbsolute = await _extractMediaFilesFromArchive(archive);

      final rawFolders = decoded['folders'] as List<dynamic>;
      final rawNotes = decoded['notes'] as List<dynamic>;
      final rawTodos = decoded['todos'] as List<dynamic>;

      final folders = rawFolders.map(_folderFromJson).toList(growable: false);
      final notes = rawNotes
          .map((entry) => _noteFromJson(
                entry,
                relativeToAbsolute: relativeToAbsolute,
              ))
          .toList(growable: false);
      final todoNodes = <_TodoNode>[];
      final visited = <int>{};
      for (final entry in rawTodos) {
        todoNodes.add(_todoNodeFromJson(
          entry,
          visited: visited,
          depth: 0,
        ));
      }

      await db.writeTxn(() async {
        if (mode == ImportMode.replace) {
          await db.noteIsars.clear();
          await db.folderIsars.clear();
          await db.todoIsars.clear();
        }

        if (folders.isNotEmpty) {
          await db.folderIsars.putAll(folders);
        }
        if (notes.isNotEmpty) {
          await db.noteIsars.putAll(notes);
        }

        await _upsertTodoTree(todoNodes);
      });
    } on BackupFormatException {
      rethrow;
    } on BackupImportException {
      rethrow;
    } catch (e) {
      throw BackupImportException('Failed to import backup: $e');
    }
  }

  Future<void> _upsertTodoTree(List<_TodoNode> roots) async {
    if (roots.isEmpty) return;

    final allNodes = <_TodoNode>[];
    final childIdsByParent = <int, List<int>>{};

    void flatten(_TodoNode node) {
      allNodes.add(node);
      if (node.children.isNotEmpty) {
        childIdsByParent[node.todo.id] =
            node.children.map((child) => child.todo.id).toList(growable: false);
      } else {
        childIdsByParent[node.todo.id] = const <int>[];
      }
      for (final child in node.children) {
        flatten(child);
      }
    }

    for (final root in roots) {
      flatten(root);
    }

    final incomingIds = allNodes.map((node) => node.todo.id).toSet();
    final staleSubtaskIds = <int>{};

    final existing = await db.todoIsars.getAll(incomingIds.toList(growable: false));
    for (final todo in existing.whereType<TodoIsar>()) {
      await todo.subtasks.load();
      final expectedChildren = childIdsByParent[todo.id]?.toSet() ?? const <int>{};
      for (final sub in todo.subtasks) {
        if (!expectedChildren.contains(sub.id)) {
          staleSubtaskIds.add(sub.id);
        }
      }
    }

    final todosToPut = allNodes.map((node) => node.todo).toList(growable: false);
    await db.todoIsars.putAll(todosToPut);

    if (staleSubtaskIds.isNotEmpty) {
      await db.todoIsars.deleteAll(staleSubtaskIds.toList(growable: false));
    }

    final todoById = {for (final todo in todosToPut) todo.id: todo};
    for (final node in allNodes) {
      node.todo.subtasks.clear();
      final childIds = childIdsByParent[node.todo.id] ?? const <int>[];
      for (final childId in childIds) {
        final child = todoById[childId];
        if (child != null) {
          node.todo.subtasks.add(child);
        }
      }
      await node.todo.subtasks.save();
      await db.todoIsars.put(node.todo);
    }
  }

  Future<void> _loadTodoTree(TodoIsar todo) async {
    await todo.subtasks.load();
    for (final sub in todo.subtasks) {
      await _loadTodoTree(sub);
    }
  }

  Map<String, dynamic> _noteToJson(
    NoteIsar note, {
    required Map<String, String> absoluteToRelative,
  }) {
    final rewrittenDelta = _rewriteDeltaImagesAbsoluteToRelative(
      note.richTextDeltaJson,
      absoluteToRelative,
    );

    return <String, dynamic>{
      'id': note.id,
      'title': note.title,
      'titleRichTextDeltaJson': note.titleRichTextDeltaJson,
      'text': note.text,
      'richTextDeltaJson': rewrittenDelta,
      'isCompleted': note.isCompleted,
      'reminder': note.reminder?.toUtc().toIso8601String(),
      'isPinned': note.isPinned,
      'isArchived': note.isArchived,
      'order': note.order,
      'folderIds': note.folderIds,
    };
  }

  Future<Map<String, dynamic>> _todoToJsonRecursive(TodoIsar todo) async {
    await todo.subtasks.load();
    final children = <Map<String, dynamic>>[];
    for (final child in todo.subtasks) {
      children.add(await _todoToJsonRecursive(child));
    }

    return <String, dynamic>{
      'id': todo.id,
      'title': todo.title,
      'titleRichTextDeltaJson': todo.titleRichTextDeltaJson,
      'isCompleted': todo.isCompleted,
      'isSubtask': todo.isSubtask,
      'order': todo.order,
      'reminder': todo.reminder?.toUtc().toIso8601String(),
      'isPinned': todo.isPinned,
      'isArchived': todo.isArchived,
      'folderIds': todo.folderIds,
      'subTasks': children,
    };
  }

  Map<String, dynamic> _folderToJson(FolderIsar folder) {
    return <String, dynamic>{
      'id': folder.id,
      'name': folder.name,
      'parentId': folder.parentId,
      'order': folder.order,
      'createdAt': folder.createdAt.toUtc().toIso8601String(),
    };
  }

  FolderIsar _folderFromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      throw BackupFormatException('Folder entry must be a JSON object.');
    }

    return FolderIsar()
      ..id = _readInt(raw, 'id')
      ..name = _readString(raw, 'name')
      ..nameNormalized = _readString(raw, 'name').trim().toLowerCase()
      ..parentId = _readNullableInt(raw['parentId'], field: 'parentId')
      ..order = _readInt(raw, 'order')
      ..createdAt = _readDateTime(raw['createdAt'], field: 'createdAt');
  }

  NoteIsar _noteFromJson(
    dynamic raw, {
    required Map<String, String> relativeToAbsolute,
  }) {
    if (raw is! Map<String, dynamic>) {
      throw BackupFormatException('Note entry must be a JSON object.');
    }

    final rawDelta = _readNullableString(raw, 'richTextDeltaJson');
    final rewrittenDelta = _rewriteDeltaImagesRelativeToAbsolute(
      rawDelta,
      relativeToAbsolute,
    );

    return NoteIsar()
      ..id = _readInt(raw, 'id')
      ..title = _readString(raw, 'title')
      ..titleRichTextDeltaJson = _readNullableString(raw, 'titleRichTextDeltaJson')
      ..text = _readString(raw, 'text')
      ..richTextDeltaJson = rewrittenDelta
      ..isCompleted = _readBool(raw, 'isCompleted')
      ..reminder = _readNullableDateTime(raw['reminder'], field: 'reminder')
      ..isPinned = _readBool(raw, 'isPinned')
      ..isArchived = _readBool(raw, 'isArchived')
      ..order = _readInt(raw, 'order')
      ..folderIds = _readIntList(raw['folderIds'], field: 'folderIds');
  }

  _TodoNode _todoNodeFromJson(
    dynamic raw, {
    required Set<int> visited,
    required int depth,
  }) {
    if (raw is! Map<String, dynamic>) {
      throw BackupFormatException('Todo entry must be a JSON object.');
    }
    if (depth > 128) {
      throw BackupFormatException('Todo tree depth exceeded safety limit.');
    }

    final id = _readInt(raw, 'id');
    if (!visited.add(id)) {
      throw BackupFormatException('Duplicate or cyclic todo id detected: $id');
    }

    final todo = TodoIsar()
      ..id = id
      ..title = _readString(raw, 'title')
      ..titleRichTextDeltaJson = _readNullableString(raw, 'titleRichTextDeltaJson')
      ..isCompleted = _readBool(raw, 'isCompleted')
      ..isSubtask = _readBool(raw, 'isSubtask')
      ..order = _readInt(raw, 'order')
      ..reminder = _readNullableDateTime(raw['reminder'], field: 'reminder')
      ..isPinned = _readBool(raw, 'isPinned')
      ..isArchived = _readBool(raw, 'isArchived')
      ..folderIds = _readIntList(raw['folderIds'], field: 'folderIds');

    final rawSubTasks = raw['subTasks'];
    if (rawSubTasks is! List<dynamic>) {
      throw BackupFormatException('Todo field "subTasks" must be a list.');
    }

    final children = <_TodoNode>[];
    for (final subTask in rawSubTasks) {
      children.add(_todoNodeFromJson(
        subTask,
        visited: visited,
        depth: depth + 1,
      ));
    }
    return _TodoNode(todo: todo, children: children);
  }

  void _validateBackupStructure(Map<String, dynamic> root) {
    final metadata = root['metadata'];
    final folders = root['folders'];
    final notes = root['notes'];
    final todos = root['todos'];

    if (metadata is! Map<String, dynamic>) {
      throw BackupFormatException('metadata must be an object.');
    }
    if (folders is! List<dynamic>) {
      throw BackupFormatException('folders must be a list.');
    }
    if (notes is! List<dynamic>) {
      throw BackupFormatException('notes must be a list.');
    }
    if (todos is! List<dynamic>) {
      throw BackupFormatException('todos must be a list.');
    }
  }

  void _validateSchema(Map<String, dynamic> root) {
    final metadata = root['metadata'];
    if (metadata is! Map<String, dynamic>) {
      throw BackupFormatException('metadata must be an object.');
    }
    final schemaVersion = metadata['schemaVersion'];
    if (schemaVersion is! int) {
      throw BackupSchemaException('metadata.schemaVersion must be an integer.');
    }
    if (schemaVersion != 1 && schemaVersion != _schemaVersion) {
      throw BackupSchemaException(
        'Unsupported schemaVersion $schemaVersion. Supported: 1, $_schemaVersion.',
      );
    }
  }

  Future<Map<String, String>> _extractMediaFilesFromArchive(Archive archive) async {
    final sketchDir = await _sketchDirectory();
    final relativeToAbsolute = <String, String>{};

    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final normalized = _normalizeMediaRelativePath(entry.name);
      if (normalized == null) continue;

      final destinationPath = _resolveImportedMediaPath(
        normalized,
        sketchDir.path,
      );
      final destination = File(destinationPath);
      await destination.writeAsBytes(_readArchiveFileBytes(entry), flush: true);
      relativeToAbsolute[normalized] = destination.path;
    }

    return relativeToAbsolute;
  }

  Future<void> _appendMediaFilesToArchive({
    required Archive archive,
    required Iterable<String> absolutePaths,
    required Map<String, String> absoluteToRelative,
  }) async {
    for (final abs in absolutePaths.toSet()) {
      final file = File(abs);
      if (!await file.exists()) continue;
      final rel = absoluteToRelative[abs];
      if (rel == null) continue;
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(rel, bytes.length, bytes));
    }
  }

  String? _rewriteDeltaImagesAbsoluteToRelative(
    String? richTextDeltaJson,
    Map<String, String> absoluteToRelative,
  ) {
    if (richTextDeltaJson == null || richTextDeltaJson.trim().isEmpty) {
      return richTextDeltaJson;
    }

    final decodedOps = _decodeDelta(richTextDeltaJson);
    if (decodedOps == null) {
      return _encodeDelta(_sanitizeDeltaOps(const [], removeRelativeMedia: false));
    }

    final rewritten = <Map<String, dynamic>>[];
    for (final op in decodedOps) {
      final current = Map<String, dynamic>.from(op);
      final insert = current['insert'];
      if (insert is Map) {
        final insertMap = Map<String, dynamic>.from(insert);
        final image = insertMap['image'];
        if (image is String && sketchStorage.isOwnedSketchPath(image)) {
          insertMap['image'] = _toRelativeMediaPath(image, absoluteToRelative);
          current['insert'] = insertMap;
        }
      }
      rewritten.add(current);
    }

    return _encodeDelta(_sanitizeDeltaOps(rewritten, removeRelativeMedia: false));
  }

  String? _rewriteDeltaImagesRelativeToAbsolute(
    String? richTextDeltaJson,
    Map<String, String> relativeToAbsolute,
  ) {
    if (richTextDeltaJson == null || richTextDeltaJson.trim().isEmpty) {
      return richTextDeltaJson;
    }

    final decodedOps = _decodeDelta(richTextDeltaJson);
    if (decodedOps == null) {
      return _encodeDelta(_sanitizeDeltaOps(const [], removeRelativeMedia: true));
    }

    final rewritten = <Map<String, dynamic>>[];
    for (final op in decodedOps) {
      final current = Map<String, dynamic>.from(op);
      final insert = current['insert'];
      if (insert is Map) {
        final insertMap = Map<String, dynamic>.from(insert);
        final image = insertMap['image'];
        if (image is String) {
          final normalized = _normalizeMediaRelativePath(image);
          if (normalized != null) {
            insertMap['image'] = relativeToAbsolute[normalized] ?? normalized;
            current['insert'] = insertMap;
          }
        }
      }
      rewritten.add(current);
    }

    return _encodeDelta(_sanitizeDeltaOps(rewritten, removeRelativeMedia: true));
  }

  List<Map<String, dynamic>> _sanitizeDeltaOps(
    List<Map<String, dynamic>> ops, {
    required bool removeRelativeMedia,
  }) {
    final sanitized = <Map<String, dynamic>>[];

    for (final op in ops) {
      final insert = op['insert'];
      if (insert is Map) {
        final insertMap = Map<String, dynamic>.from(insert);
        final image = insertMap['image'];
        if (image is String) {
          if (removeRelativeMedia && _isRelativeMediaPath(image)) {
            continue;
          }
          if (sketchStorage.isOwnedSketchPath(image)) {
            final file = File(image);
            if (!file.existsSync()) {
              continue;
            }
          }
        }
      }
      sanitized.add(op);
    }

    if (sanitized.isEmpty) {
      return <Map<String, dynamic>>[
        <String, dynamic>{'insert': '\n'}
      ];
    }

    final lastInsert = sanitized.last['insert'];
    final endsWithLineBreak = lastInsert is String && lastInsert.endsWith('\n');
    if (!endsWithLineBreak) {
      sanitized.add(<String, dynamic>{'insert': '\n'});
    }
    return sanitized;
  }

  List<Map<String, dynamic>>? _decodeDelta(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return null;
      final ops = <Map<String, dynamic>>[];
      for (final op in decoded) {
        if (op is Map<String, dynamic>) {
          ops.add(Map<String, dynamic>.from(op));
        } else if (op is Map) {
          ops.add(Map<String, dynamic>.from(op.cast<String, dynamic>()));
        }
      }
      return ops;
    } catch (_) {
      return null;
    }
  }

  String _encodeDelta(List<Map<String, dynamic>> ops) {
    return jsonEncode(ops);
  }

  String _toRelativeMediaPath(
    String absolutePath,
    Map<String, String> absoluteToRelative,
  ) {
    final existing = absoluteToRelative[absolutePath];
    if (existing != null) return existing;

    final fileName = _basename(absolutePath);
    var relative = 'media/$fileName';
    if (absoluteToRelative.containsValue(relative)) {
      final hash = _stableHash8(absolutePath);
      final ext = _extension(fileName);
      final stem = _basenameWithoutExtension(fileName);
      relative = 'media/${stem}_$hash$ext';
    }
    absoluteToRelative[absolutePath] = relative;
    return relative;
  }

  String _resolveImportedMediaPath(String relativePath, String destinationDir) {
    final fileName = _basename(relativePath);
    var outputPath = _join(destinationDir, fileName);
    final output = File(outputPath);
    if (!output.existsSync()) {
      return outputPath;
    }

    final hash = _stableHash8(relativePath);
    final ext = _extension(fileName);
    final stem = _basenameWithoutExtension(fileName);
    outputPath = _join(destinationDir, '${stem}_$hash$ext');
    return outputPath;
  }

  String? _normalizeMediaRelativePath(String path) {
    final normalized = path.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) return null;
    final withoutDot = normalized.startsWith('./')
        ? normalized.substring(2)
        : normalized;
    final withoutLeadingSlash =
        withoutDot.startsWith('/') ? withoutDot.substring(1) : withoutDot;
    if (withoutLeadingSlash.startsWith('media/')) {
      return withoutLeadingSlash;
    }
    return null;
  }

  bool _isRelativeMediaPath(String path) {
    return _normalizeMediaRelativePath(path) != null;
  }

  Future<Directory> _sketchDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final directory = Directory(_join(docs.path, 'note_sketches'));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  int _readInt(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is int) return value;
    throw BackupFormatException('Field "$field" must be an integer.');
  }

  bool _readBool(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is bool) return value;
    throw BackupFormatException('Field "$field" must be a boolean.');
  }

  String _readString(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is String) return value;
    throw BackupFormatException('Field "$field" must be a string.');
  }

  String? _readNullableString(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value == null) return null;
    if (value is String) return value;
    throw BackupFormatException('Field "$field" must be a string or null.');
  }

  DateTime _readDateTime(dynamic value, {required String field}) {
    if (value is! String) {
      throw BackupFormatException('Field "$field" must be an ISO date string.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw BackupFormatException('Field "$field" has invalid date format.');
    }
    return parsed;
  }

  DateTime? _readNullableDateTime(dynamic value, {required String field}) {
    if (value == null) return null;
    return _readDateTime(value, field: field);
  }

  int? _readNullableInt(dynamic value, {required String field}) {
    if (value == null) return null;
    if (value is int) return value;
    throw BackupFormatException('Field "$field" must be an integer or null.');
  }

  List<int> _readIntList(dynamic value, {required String field}) {
    if (value == null) return <int>[];
    if (value is! List<dynamic>) {
      throw BackupFormatException('Field "$field" must be a list of integers.');
    }
    final output = <int>[];
    for (final item in value) {
      if (item is! int) {
        throw BackupFormatException('Field "$field" must contain integers only.');
      }
      output.add(item);
    }
    return output;
  }

  Uint8List _readArchiveFileBytes(ArchiveFile file) {
    return Uint8List.fromList(file.content);
  }
}

class _TodoNode {
  final TodoIsar todo;
  final List<_TodoNode> children;

  _TodoNode({
    required this.todo,
    required this.children,
  });
}

String _stableHash8(String input) {
  var hash = 2166136261;
  for (final codeUnit in input.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }
  return hash.abs().toRadixString(16).padLeft(8, '0').substring(0, 8);
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final idx = normalized.lastIndexOf('/');
  return idx >= 0 ? normalized.substring(idx + 1) : normalized;
}

String _extension(String path) {
  final file = _basename(path);
  final idx = file.lastIndexOf('.');
  if (idx <= 0 || idx == file.length - 1) return '';
  return file.substring(idx);
}

String _basenameWithoutExtension(String path) {
  final file = _basename(path);
  final idx = file.lastIndexOf('.');
  if (idx <= 0) return file;
  return file.substring(0, idx);
}

String _join(String left, String right) {
  if (left.endsWith(Platform.pathSeparator)) {
    return '$left$right';
  }
  return '$left${Platform.pathSeparator}$right';
}

BackupService createBackupService(
  Isar db, {
  NoteSketchStorageService? sketchStorage,
}) {
  return BackupServiceImpl(
    db,
    sketchStorage: sketchStorage,
  );
}

Future<File?> pickBackupZip() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['zip'],
  );
  if (result == null || result.files.isEmpty) return null;
  final path = result.files.single.path;
  if (path == null || path.isEmpty) return null;
  return File(path);
}

Future<void> shareBackupZip(File zipFile) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(zipFile.path)],
      text: 'ToDo app backup',
    ),
  );
}
