import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';

enum NoteViewMode { grid, list }

class NoteViewModeCubit extends Cubit<NoteViewMode> {
  NoteViewModeCubit() : super(_initialMode());

  static NoteViewMode _initialMode() {
    return LocalStorage.notesViewMode == 'list'
        ? NoteViewMode.list
        : NoteViewMode.grid;
  }

  void setMode(NoteViewMode mode) {
    LocalStorage.notesViewMode = mode.name;
    emit(mode);
  }

  void toggle() {
    if (state == NoteViewMode.grid) {
      setMode(NoteViewMode.list);
      return;
    }
    setMode(NoteViewMode.grid);
  }
}
