import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:to_do_app/domain/models/note.dart';

class PinnedNoteWidgetService {
  static const String _androidWidgetName = 'PinnedNoteHomeWidgetProvider';
  static const String _iosWidgetName = 'PinnedNoteHomeWidget';
  static const String _appGroupId = 'group.com.example.to_do_app';

  static const String pinnedNoteIdKey = 'pinnedNoteId';
  static const String pinnedNoteTitleKey = 'pinnedNoteTitle';
  static const String pinnedNotePreviewKey = 'pinnedNotePreview';
  static const String pinnedNoteUpdatedAtKey = 'pinnedNoteUpdatedAt';

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
  }

  static Future<int?> getPinnedNoteId() async {
    if (!_isSupportedPlatform) return null;
    try {
      final raw = await HomeWidget.getWidgetData<dynamic>(pinnedNoteIdKey);
      final parsed = _coerceId(raw);
      if (parsed != null) {
        // Migrate any legacy numeric storage to string storage.
        await HomeWidget.saveWidgetData<String>(pinnedNoteIdKey, parsed.toString());
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isPinned(int noteId) async {
    return (await getPinnedNoteId()) == noteId;
  }

  static Future<void> pinNote(Note note) async {
    if (!_isSupportedPlatform) return;
    await _saveSnapshot(note);
    await _updateWidgets();
  }

  static Future<void> clearPinnedNote() async {
    if (!_isSupportedPlatform) return;
    await HomeWidget.saveWidgetData<String?>(pinnedNoteIdKey, null);
    await HomeWidget.saveWidgetData<String?>(pinnedNoteTitleKey, null);
    await HomeWidget.saveWidgetData<String?>(pinnedNotePreviewKey, null);
    await HomeWidget.saveWidgetData<String?>(pinnedNoteUpdatedAtKey, null);
    await _updateWidgets();
  }

  static Future<void> refreshFromNotes(List<Note> notes) async {
    final pinnedId = await getPinnedNoteId();
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

    await _saveSnapshot(pinned);
    await _updateWidgets();
  }

  static Future<void> _saveSnapshot(Note note) async {
    await HomeWidget.saveWidgetData<String>(pinnedNoteIdKey, note.id.toString());
    await HomeWidget.saveWidgetData<String>(pinnedNoteTitleKey, _safeTitle(note));
    await HomeWidget.saveWidgetData<String>(
      pinnedNotePreviewKey,
      _buildPreview(note.text),
    );
    await HomeWidget.saveWidgetData<String>(
      pinnedNoteUpdatedAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  static Future<void> _updateWidgets() async {
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: _iosWidgetName,
    );
  }

  static String _safeTitle(Note note) {
    final normalized = note.title.trim();
    if (normalized.isEmpty) return 'Untitled note';
    return normalized;
  }

  static String _buildPreview(String text) {
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

  static int? _coerceId(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return int.tryParse(raw.toString());
  }
}
