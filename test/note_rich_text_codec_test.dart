import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/common/utils/note_rich_text_codec.dart';
import 'package:to_do_app/domain/models/note.dart';

void main() {
  test('documentFromNote falls back to plain text when payload is invalid', () {
    final note = Note(
      id: 1,
      title: 'Title',
      text: 'Hello world',
      richTextDeltaJson: '{invalid',
    );

    final doc = NoteRichTextCodec.documentFromNote(note);

    expect(NoteRichTextCodec.extractPlainText(doc), 'Hello world');
  });

  test('encodeDelta and decode preserve formatted content', () {
    final doc = NoteRichTextCodec.documentFromPlainText('Hello');
    final encoded = NoteRichTextCodec.encodeDelta(doc);
    final note = Note(
      id: 1,
      title: 'Title',
      text: 'Hello',
      richTextDeltaJson: encoded,
    );

    final decoded = NoteRichTextCodec.documentFromNote(note);

    expect(NoteRichTextCodec.extractPlainText(decoded), 'Hello');
  });

  test('extractPlainText removes terminal editor newline', () {
    final doc = NoteRichTextCodec.documentFromPlainText('Line');

    expect(NoteRichTextCodec.extractPlainText(doc), 'Line');
  });
}
