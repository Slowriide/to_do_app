import 'dart:async';

import 'package:flutter_quill/flutter_quill.dart' as quill;

class QuillAutoLinker {
  static final RegExp _urlPattern = RegExp(
    r'((https?:\/\/|www\.)[^\s<]+)',
    caseSensitive: false,
  );
  static final RegExp _emailPattern = RegExp(
    r'(?<![A-Z0-9._%+-])([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,})(?![A-Z0-9._%+-])',
    caseSensitive: false,
  );
  static final RegExp _phonePattern = RegExp(
    r'(?<!\w)((?:\+|00)?(?:\d[\s().-]?){7,16}\d)(?!\w)',
    caseSensitive: false,
  );

  final quill.QuillController _controller;
  bool _isApplying = false;
  late String _lastPlainText;
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 250);

  QuillAutoLinker(this._controller) {
    _lastPlainText = _plainText;
    _controller.addListener(_onChanged);
    _applyLinks();
  }

  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onChanged);
  }

  void _onChanged() {
    if (_isApplying) return;
    final plainText = _plainText;
    if (plainText == _lastPlainText) return;
    _lastPlainText = plainText;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _applyLinks);
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
      final occupiedRanges = <_Range>[];
      final detected = <_DetectedLink>[];

      _collectMatches(
        source: text,
        pattern: _urlPattern,
        kind: _LinkKind.url,
        occupiedRanges: occupiedRanges,
        output: detected,
      );
      _collectMatches(
        source: text,
        pattern: _emailPattern,
        kind: _LinkKind.email,
        occupiedRanges: occupiedRanges,
        output: detected,
      );
      _collectMatches(
        source: text,
        pattern: _phonePattern,
        kind: _LinkKind.phone,
        occupiedRanges: occupiedRanges,
        output: detected,
      );

      for (final item in detected) {
        final linkValue = switch (item.kind) {
          _LinkKind.url => _normalizeUrl(item.text),
          _LinkKind.email => _normalizeEmail(item.text),
          _LinkKind.phone => _normalizePhone(item.text),
        };
        if (linkValue == null || linkValue.isEmpty) continue;

        final currentLink = _controller.document
            .collectStyle(item.start, item.length)
            .attributes[quill.Attribute.link.key]
            ?.value
            ?.toString();

        if (currentLink != linkValue) {
          _controller.formatText(
            item.start,
            item.length,
            quill.Attribute.fromKeyValue(quill.Attribute.link.key, linkValue),
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

  String _normalizeEmail(String value) {
    final email = value.trim();
    final at = email.indexOf('@');
    if (at <= 0 || at >= email.length - 1) return 'mailto:$email';
    final local = email.substring(0, at);
    final domain = email.substring(at + 1).toLowerCase();
    return 'mailto:$local@$domain';
  }

  String? _normalizePhone(String value) {
    var compact = value.trim().replaceAll(RegExp(r'[\s().-]'), '');
    if (compact.isEmpty) return null;

    var hasPlus = compact.startsWith('+');

    if (!hasPlus && compact.startsWith('00')) {
      compact = compact.substring(2);
      hasPlus = true;
    } else if (hasPlus) {
      compact = compact.substring(1);
    }

    var digits = compact.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    if (digits.length < 7 || digits.length > 15) return null;
    final normalized = hasPlus ? '+$digits' : digits;
    return 'tel:$normalized';
  }

  void _collectMatches({
    required String source,
    required RegExp pattern,
    required _LinkKind kind,
    required List<_Range> occupiedRanges,
    required List<_DetectedLink> output,
  }) {
    for (final match in pattern.allMatches(source)) {
      final raw = match.group(0);
      if (raw == null || raw.isEmpty) continue;

      final trimmed = _trimTrailingPunctuation(raw);
      if (trimmed.isEmpty) continue;

      final start = match.start;
      final end = start + trimmed.length;
      if (_overlaps(occupiedRanges, start, end)) continue;

      occupiedRanges.add(_Range(start: start, end: end));
      output.add(_DetectedLink(
        kind: kind,
        start: start,
        text: trimmed,
      ));
    }
  }

  bool _overlaps(List<_Range> ranges, int start, int end) {
    for (final range in ranges) {
      if (start < range.end && end > range.start) return true;
    }
    return false;
  }
}

enum _LinkKind { url, email, phone }

class _Range {
  final int start;
  final int end;

  _Range({
    required this.start,
    required this.end,
  });
}

class _DetectedLink {
  final _LinkKind kind;
  final int start;
  final String text;

  _DetectedLink({
    required this.kind,
    required this.start,
    required this.text,
  });

  int get length => text.length;
}
