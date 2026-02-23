import 'package:flutter_quill/flutter_quill.dart' as quill;

class QuillAutoLinker {
  static final RegExp _urlPattern = RegExp(
    r'((https?:\/\/|www\.)[^\s]+)',
    caseSensitive: false,
  );

  final quill.QuillController _controller;
  bool _isApplying = false;
  late String _lastPlainText;

  QuillAutoLinker(this._controller) {
    _lastPlainText = _plainText;
    _controller.addListener(_onChanged);
    _applyLinks();
  }

  void dispose() {
    _controller.removeListener(_onChanged);
  }

  void _onChanged() {
    if (_isApplying) return;
    final plainText = _plainText;
    if (plainText == _lastPlainText) return;
    _lastPlainText = plainText;
    _applyLinks();
  }

  String get _plainText {
    final raw = _controller.document.toPlainText();
    if (raw.endsWith('\n')) {
      return raw.substring(0, raw.length - 1);
    }
    return raw;
  }

  void _applyLinks() {
    final text = _plainText;
    if (text.isEmpty) return;

    _isApplying = true;
    try {
      for (final match in _urlPattern.allMatches(text)) {
        final rawMatch = match.group(0);
        if (rawMatch == null || rawMatch.isEmpty) continue;

        final trimmed = _trimTrailingPunctuation(rawMatch);
        if (trimmed.isEmpty) continue;

        final start = match.start;
        final linkValue = _normalizeUrl(trimmed);

        final currentLink = _controller.document
            .collectStyle(start, trimmed.length)
            .attributes[quill.Attribute.link.key]
            ?.value
            ?.toString();

        if (currentLink != linkValue) {
          _controller.formatText(
            start,
            trimmed.length,
            quill.Attribute.fromKeyValue(quill.Attribute.link.key, linkValue),
          );
        }

        final trailingLength = rawMatch.length - trimmed.length;
        if (trailingLength > 0) {
          _controller.formatText(
            start + trimmed.length,
            trailingLength,
            quill.Attribute.fromKeyValue(quill.Attribute.link.key, null),
          );
        }
      }
    } finally {
      _isApplying = false;
    }
  }

  String _trimTrailingPunctuation(String value) {
    var end = value.length;
    while (end > 0) {
      final char = value[end - 1];
      if (char == '.' ||
          char == ',' ||
          char == ';' ||
          char == ':' ||
          char == '!' ||
          char == '?' ||
          char == ')' ||
          char == ']') {
        end -= 1;
        continue;
      }
      break;
    }
    return value.substring(0, end);
  }

  String _normalizeUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return 'https://$value';
  }
}
