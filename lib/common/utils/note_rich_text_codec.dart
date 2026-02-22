import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:to_do_app/domain/models/note.dart';

class NoteRichTextCodec {
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
          return quill.Document.fromJson(decoded.cast<Map<String, dynamic>>());
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
}
