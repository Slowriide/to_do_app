import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/presentation/cubits/notes/note_view_mode_cubit.dart';

void main() {
  Future<NoteViewModeCubit> createCubitWithPrefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    await LocalStorage.configurePrefs();
    return NoteViewModeCubit();
  }

  test('initializes to grid when preference is missing', () async {
    final cubit = await createCubitWithPrefs({});

    expect(cubit.state, NoteViewMode.grid);
    expect(LocalStorage.notesViewMode, 'grid');
    await cubit.close();
  });

  test('initializes to grid when preference is invalid', () async {
    final cubit = await createCubitWithPrefs({'notesViewMode': 'cards'});

    expect(cubit.state, NoteViewMode.grid);
    expect(LocalStorage.notesViewMode, 'grid');
    await cubit.close();
  });

  test('initializes to saved list preference', () async {
    final cubit = await createCubitWithPrefs({'notesViewMode': 'list'});

    expect(cubit.state, NoteViewMode.list);
    expect(LocalStorage.notesViewMode, 'list');
    await cubit.close();
  });

  test('toggle updates state and persists value', () async {
    final cubit = await createCubitWithPrefs({});

    cubit.toggle();
    expect(cubit.state, NoteViewMode.list);
    expect(LocalStorage.notesViewMode, 'list');

    cubit.toggle();
    expect(cubit.state, NoteViewMode.grid);
    expect(LocalStorage.notesViewMode, 'grid');
    await cubit.close();
  });

  test('setMode persists exact value', () async {
    final cubit = await createCubitWithPrefs({});

    cubit.setMode(NoteViewMode.list);
    expect(cubit.state, NoteViewMode.list);
    expect(LocalStorage.notesViewMode, 'list');

    cubit.setMode(NoteViewMode.grid);
    expect(cubit.state, NoteViewMode.grid);
    expect(LocalStorage.notesViewMode, 'grid');
    await cubit.close();
  });
}
