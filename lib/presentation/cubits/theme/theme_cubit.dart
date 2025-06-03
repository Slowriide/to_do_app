import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';

part 'theme_state.dart';

/// Cubit responsible for managing the app's theme state.
///
/// Controls whether the app is in dark mode or light mode,
/// syncing the state with local storage via [LocalStorage].
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({bool darkMode = true})
      : super(ThemeState(isDarkmode: LocalStorage.isDarkMode));

  void toggleTheme() {
    final newMode = !state.isDarkmode;
    LocalStorage.isDarkMode = newMode;
    emit(ThemeState(isDarkmode: newMode));
  }

  void setLightMode() {
    LocalStorage.isDarkMode = false;
    emit(ThemeState(isDarkmode: false));
  }

  void setDarkMode() {
    LocalStorage.isDarkMode = true;
    emit(ThemeState(isDarkmode: true));
  }
}
