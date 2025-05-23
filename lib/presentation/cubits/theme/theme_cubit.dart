import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({bool darkMode = true}) : super(ThemeState(isDarkmode: darkMode));

  void toggleTheme() {
    emit(ThemeState(isDarkmode: !state.isDarkmode));
  }

  void setLightMode() {
    emit(ThemeState(isDarkmode: false));
  }

  void setDarkMode() {
    emit(ThemeState(isDarkmode: true));
  }
}
