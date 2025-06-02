import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';

part 'theme_state.dart';

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
