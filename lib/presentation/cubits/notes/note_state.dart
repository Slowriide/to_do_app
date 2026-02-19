import 'package:to_do_app/domain/models/note.dart';

enum NoteStatus { loading, success, error }

class NoteState {
  final NoteStatus status;
  final List<Note> notes;
  final String? errorMessage;

  const NoteState({
    required this.status,
    required this.notes,
    this.errorMessage,
  });

  const NoteState.loading([List<Note> notes = const []])
      : this(status: NoteStatus.loading, notes: notes);

  const NoteState.success(List<Note> notes)
      : this(status: NoteStatus.success, notes: notes);

  const NoteState.error(String message, [List<Note> notes = const []])
      : this(
          status: NoteStatus.error,
          notes: notes,
          errorMessage: message,
        );
}
