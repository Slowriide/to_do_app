import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:to_do_app/common/utils/local_file_exists.dart';
import 'package:to_do_app/domain/models/note.dart';

class NoteRichTextCodec {
  static final RegExp _ownedSketchPathPattern =
      RegExp(r'(^|[\\/])note_sketches([\\/])');

  static quill.Document documentFromNote(Note note) {
    return documentFromRaw(
      rawDelta: note.richTextDeltaJson,
      fallbackPlainText: note.text,
    );
  }

  static quill.Document titleDocumentFromNote(Note note) {
    return documentFromRaw(
      rawDelta: note.titleRichTextDeltaJson,
      fallbackPlainText: note.title,
    );
  }

  static quill.Document documentFromRaw({
    required String? rawDelta,
    required String fallbackPlainText,
  }) {
    if (rawDelta != null && rawDelta.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawDelta);
        if (decoded is List) {
          final sanitized = _sanitizeDelta(decoded);
          return quill.Document.fromJson(sanitized);
        }
      } catch (_) {
        // Fallback to plain text decoding for malformed rich text payloads.
      }
    }
    return documentFromPlainText(fallbackPlainText);
  }

  static quill.Document documentFromPlainText(String text) {
    final normalized = text.endsWith('\n') ? text : '$text\n';
    return quill.Document.fromJson([
      {'insert': normalized}
    ]);
  }

  static String encodeDelta(quill.Document document) {
    return jsonEncode(document.toDelta().toJson());
  }

  static String extractPlainText(quill.Document document) {
    final raw = document.toPlainText();
    if (raw.endsWith('\n')) {
      return raw.substring(0, raw.length - 1);
    }
    return raw;
  }

  static List<Map<String, dynamic>> _sanitizeDelta(List<dynamic> decoded) {
    final sanitized = <Map<String, dynamic>>[];
    for (final op in decoded) {
      if (op is! Map<String, dynamic>) continue;

      final insert = op['insert'];
      if (insert is Map<String, dynamic>) {
        final image = insert['image'];
        if (image is String &&
            _isOwnedSketchPath(image) &&
            !localFileExists(image)) {
          continue;
        }
      }

      sanitized.add(op);
    }

    if (sanitized.isEmpty) {
      return [
        {'insert': '\n'}
      ];
    }

    final lastInsert = sanitized.last['insert'];
    final endsWithNewLine = lastInsert is String && lastInsert.endsWith('\n');
    if (!endsWithNewLine) {
      sanitized.add({'insert': '\n'});
    }
    return sanitized;
  }

  static bool _isOwnedSketchPath(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return false;
    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.hasScheme) return false;
    return _ownedSketchPathPattern.hasMatch(normalized);
  }
}
