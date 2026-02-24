import 'dart:convert';
import 'dart:typed_data';

abstract class NoteSketchStorageService {
  static final RegExp _ownedPathPattern =
      RegExp(r'(^|[\\/])note_sketches([\\/])');

  Future<String> savePng(Uint8List bytes);

  Future<void> deleteFiles(Iterable<String> paths);

  bool isOwnedSketchPath(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty) return false;
    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.hasScheme) return false;
    return _ownedPathPattern.hasMatch(normalized);
  }

  Set<String> extractOwnedSketchPathsFromDelta(String? richTextDeltaJson) {
    if (richTextDeltaJson == null || richTextDeltaJson.trim().isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(richTextDeltaJson);
      if (decoded is! List) return {};

      final extracted = <String>{};
      for (final op in decoded) {
        if (op is! Map<String, dynamic>) continue;
        final insert = op['insert'];
        if (insert is! Map<String, dynamic>) continue;
        final image = insert['image'];
        if (image is! String) continue;
        if (isOwnedSketchPath(image)) extracted.add(image);
      }
      return extracted;
    } catch (_) {
      return {};
    }
  }
}
