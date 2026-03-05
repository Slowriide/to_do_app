import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/models/todo.dart';

class PinnedNoteWidgetService {
  static const String _noteAndroidWidgetName = 'PinnedNoteHomeWidgetProvider';
  static const String _noteIosWidgetName = 'PinnedNoteHomeWidget';
  static const String _todoAndroidWidgetName = 'PinnedTodoHomeWidgetProvider';
  static const String _todoIosWidgetName = 'PinnedTodoHomeWidget';
  static const String _appGroupId = 'group.com.thiagogobbi.dailynotes';

  static const String _noteIdKey = 'pinnedNoteId';
  static const String _noteTitleKey = 'pinnedNoteTitle';
  static const String _notePreviewKey = 'pinnedNotePreview';
  static const String _noteUpdatedAtKey = 'pinnedNoteUpdatedAt';

  static const String _todoIdKey = 'pinnedTodoId';
  static const String _todoTitleKey = 'pinnedTodoTitle';
  static const String _todoPreviewKey = 'pinnedTodoPreview';
  static const String _todoUpdatedAtKey = 'pinnedTodoUpdatedAt';

  // Legacy generic keys migrated to dedicated note/todo keys.
  static const String _legacyPinnedItemTypeKey = 'pinnedItemType';
  static const String _legacyPinnedItemIdKey = 'pinnedItemId';
  static const String _legacyPinnedItemTitleKey = 'pinnedItemTitle';
  static const String _legacyPinnedItemPreviewKey = 'pinnedItemPreview';

  static bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<void> initialize() async {
    if (!_isSupportedPlatform) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await HomeWidget.setAppGroupId(_appGroupId);
    }
    await _migrateLegacyPinnedItemIfNeeded();
  }

  static Future<bool> isPinned(int noteId) async {
    return (await _getPinnedNoteId()) == noteId;
  }

  static Future<bool> isPinnedTodo(int todoId) async {
    return (await _getPinnedTodoId()) == todoId;
  }

  static Future<void> pinNote(Note note) async {
    if (!_isSupportedPlatform) return;
    await HomeWidget.saveWidgetData<String>(_noteIdKey, note.id.toString());
    await HomeWidget.saveWidgetData<String>(
        _noteTitleKey, _safeTitle(note.title));
    await HomeWidget.saveWidgetData<String>(
        _notePreviewKey, _buildNotePreview(note.text));
    await HomeWidget.saveWidgetData<String>(
      _noteUpdatedAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
    await _updateNoteWidget();
  }

  static Future<void> pinTodo(Todo todo) async {
    if (!_isSupportedPlatform) return;
    await HomeWidget.saveWidgetData<String>(_todoIdKey, todo.id.toString());
    await HomeWidget.saveWidgetData<String>(
        _todoTitleKey, _safeTitle(todo.title));
    await HomeWidget.saveWidgetData<String>(
        _todoPreviewKey, _buildTodoPreview(todo));
    await HomeWidget.saveWidgetData<String>(
      _todoUpdatedAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
    await _updateTodoWidget();
  }

  static Future<void> clearPinnedNote() async {
    if (!_isSupportedPlatform) return;
    await HomeWidget.saveWidgetData<String?>(_noteIdKey, null);
    await HomeWidget.saveWidgetData<String?>(_noteTitleKey, null);
    await HomeWidget.saveWidgetData<String?>(_notePreviewKey, null);
    await HomeWidget.saveWidgetData<String?>(_noteUpdatedAtKey, null);
    await _updateNoteWidget();
  }

  static Future<void> clearPinnedTodo() async {
    if (!_isSupportedPlatform) return;
    await HomeWidget.saveWidgetData<String?>(_todoIdKey, null);
    await HomeWidget.saveWidgetData<String?>(_todoTitleKey, null);
    await HomeWidget.saveWidgetData<String?>(_todoPreviewKey, null);
    await HomeWidget.saveWidgetData<String?>(_todoUpdatedAtKey, null);
    await _updateTodoWidget();
  }

  static Future<void> refreshFromNotes(List<Note> notes) async {
    final pinnedId = await _getPinnedNoteId();
    if (pinnedId == null) return;

    Note? pinned;
    for (final note in notes) {
      if (note.id == pinnedId) {
        pinned = note;
        break;
      }
    }

    if (pinned == null) {
      await clearPinnedNote();
      return;
    }
    await pinNote(pinned);
  }

  static Future<void> refreshFromTodos(List<Todo> todos) async {
    final pinnedId = await _getPinnedTodoId();
    if (pinnedId == null) return;

    Todo? pinned;
    for (final todo in todos) {
      if (todo.id == pinnedId) {
        pinned = todo;
        break;
      }
    }

    if (pinned == null) {
      await clearPinnedTodo();
      return;
    }
    await pinTodo(pinned);
  }

  static Future<void> _updateNoteWidget() async {
    await HomeWidget.updateWidget(
      androidName: _noteAndroidWidgetName,
      iOSName: _noteIosWidgetName,
    );
  }

  static Future<void> _updateTodoWidget() async {
    await HomeWidget.updateWidget(
      androidName: _todoAndroidWidgetName,
      iOSName: _todoIosWidgetName,
    );
  }

  static Future<int?> _getPinnedNoteId() async {
    if (!_isSupportedPlatform) return null;
    try {
      final raw = await HomeWidget.getWidgetData<dynamic>(_noteIdKey);
      return _coerceId(raw);
    } catch (e, st) {
      debugPrint('widget/getPinnedNoteId failed: $e\n$st');
      return null;
    }
  }

  static Future<int?> _getPinnedTodoId() async {
    if (!_isSupportedPlatform) return null;
    try {
      final raw = await HomeWidget.getWidgetData<dynamic>(_todoIdKey);
      return _coerceId(raw);
    } catch (e, st) {
      debugPrint('widget/getPinnedTodoId failed: $e\n$st');
      return null;
    }
  }

  static String _safeTitle(String title) {
    final normalized = title.trim();
    if (normalized.isEmpty) return 'Untitled';
    return normalized;
  }

  static String _buildNotePreview(String text) {
    final normalized = text
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(3)
        .join('\n');
    if (normalized.isEmpty) return 'No content';
    if (normalized.length <= 180) return normalized;
    return '${normalized.substring(0, 180).trimRight()}...';
  }

  static String _buildTodoPreview(Todo todo) {
    final lines = todo.subTasks
        .where((subtask) => subtask.title.trim().isNotEmpty)
        .map((subtask) => subtask.title.trim())
        .take(3)
        .join('\n');
    if (lines.isNotEmpty) return lines;
    return 'No subtasks';
  }

  static int? _coerceId(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return int.tryParse(raw.toString());
  }

  static Future<void> _migrateLegacyPinnedItemIfNeeded() async {
    try {
      final legacyType =
          await HomeWidget.getWidgetData<String>(_legacyPinnedItemTypeKey);
      final legacyId =
          await HomeWidget.getWidgetData<dynamic>(_legacyPinnedItemIdKey);
      final legacyTitle =
          await HomeWidget.getWidgetData<String>(_legacyPinnedItemTitleKey);
      final legacyPreview =
          await HomeWidget.getWidgetData<String>(_legacyPinnedItemPreviewKey);
      final id = _coerceId(legacyId);
      if (legacyType == null || id == null) return;

      if (legacyType == 'todo' && await _getPinnedTodoId() == null) {
        await HomeWidget.saveWidgetData<String>(_todoIdKey, id.toString());
        if (legacyTitle != null) {
          await HomeWidget.saveWidgetData<String>(_todoTitleKey, legacyTitle);
        }
        if (legacyPreview != null) {
          await HomeWidget.saveWidgetData<String>(
              _todoPreviewKey, legacyPreview);
        }
      } else if (legacyType == 'note' && await _getPinnedNoteId() == null) {
        await HomeWidget.saveWidgetData<String>(_noteIdKey, id.toString());
        if (legacyTitle != null) {
          await HomeWidget.saveWidgetData<String>(_noteTitleKey, legacyTitle);
        }
        if (legacyPreview != null) {
          await HomeWidget.saveWidgetData<String>(
              _notePreviewKey, legacyPreview);
        }
      }

      await HomeWidget.saveWidgetData<String?>(_legacyPinnedItemTypeKey, null);
      await HomeWidget.saveWidgetData<String?>(_legacyPinnedItemIdKey, null);
      await HomeWidget.saveWidgetData<String?>(_legacyPinnedItemTitleKey, null);
      await HomeWidget.saveWidgetData<String?>(
          _legacyPinnedItemPreviewKey, null);
    } catch (e, st) {
      debugPrint('widget/legacy-migration failed: $e\n$st');
    }
  }
}

