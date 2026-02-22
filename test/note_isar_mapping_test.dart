import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/data/models/isar_note.dart';
import 'package:to_do_app/domain/models/note.dart';

void main() {
  test('NoteIsar maps rich text payload round-trip', () {
    final note = Note(
      id: 7,
      title: 'title',
      titleRichTextDeltaJson: '[{"insert":"title\\n"}]',
      text: 'plain',
      richTextDeltaJson: '[{"insert":"plain\\n"}]',
      isPinned: true,
      isArchived: false,
      order: 4,
    );

    final isar = NoteIsar.fromDomain(note);
    final roundTrip = isar.toDomain();

    expect(roundTrip.id, note.id);
    expect(roundTrip.text, note.text);
    expect(roundTrip.richTextDeltaJson, note.richTextDeltaJson);
    expect(roundTrip.title, note.title);
    expect(roundTrip.titleRichTextDeltaJson, note.titleRichTextDeltaJson);
  });
}
