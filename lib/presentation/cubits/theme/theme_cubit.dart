import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/config/theme/theme_presets.dart';

part 'theme_state.dart';

enum ThemeColorSource { preset, custom }

/// Cubit responsible for managing the app's theme state.
///
/// Controls whether the app is in dark mode or light mode,
/// syncing the state with local storage via [LocalStorage].
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({bool darkMode = true})
      : super(_buildInitialState());

  static ThemeState _buildInitialState() {
    final custom = _normalizeHex(LocalStorage.customThemeHex);
    final source = _parseSource(LocalStorage.themeColorSource);
    final effectiveSource =
        source == ThemeColorSource.custom && custom == null
            ? ThemeColorSource.preset
            : source;
    return ThemeState(
      isDarkmode: LocalStorage.isDarkMode,
      presetId: _resolvePresetId(LocalStorage.themePresetId),
      customColorHex: custom,
      activeColorSource: effectiveSource,
    );
  }

  static ThemeColorSource _parseSource(String raw) {
    return raw == ThemeColorSource.custom.name
        ? ThemeColorSource.custom
        : ThemeColorSource.preset;
  }

  static String _resolvePresetId(String value) {
    final exists = themePresets.any((preset) => preset.id == value);
    if (exists) return value;
    return themePresets.first.id;
  }

  static final RegExp _hexPattern = RegExp(r'^[0-9A-Fa-f]{6}$');
  static String? _normalizeHex(String? input) {
    if (input == null) return null;
    final raw = input.trim();
    if (raw.isEmpty) return null;
    final normalized = raw.startsWith('#') ? raw.substring(1) : raw;
    if (!_hexPattern.hasMatch(normalized)) return null;
    return '#${normalized.toUpperCase()}';
  }

  void toggleTheme() {
    final newMode = !state.isDarkmode;
    LocalStorage.isDarkMode = newMode;
    emit(state.copyWith(isDarkmode: newMode));
  }

  void setLightMode() {
    LocalStorage.isDarkMode = false;
    emit(state.copyWith(isDarkmode: false));
  }

  void setDarkMode() {
    LocalStorage.isDarkMode = true;
    emit(state.copyWith(isDarkmode: true));
  }

  void selectPreset(String presetId) {
    final resolvedPresetId = _resolvePresetId(presetId);
    LocalStorage.themePresetId = resolvedPresetId;
    LocalStorage.themeColorSource = ThemeColorSource.preset.name;
    emit(
      state.copyWith(
        presetId: resolvedPresetId,
        activeColorSource: ThemeColorSource.preset,
      ),
    );
  }

  bool setCustomColorHex(String hex) {
    final normalized = _normalizeHex(hex);
    if (normalized == null) return false;

    LocalStorage.customThemeHex = normalized;
    LocalStorage.themeColorSource = ThemeColorSource.custom.name;
    emit(
      state.copyWith(
        customColorHex: normalized,
        activeColorSource: ThemeColorSource.custom,
      ),
    );
    return true;
  }

  void clearCustomColor() {
    LocalStorage.themeColorSource = ThemeColorSource.preset.name;
    emit(state.copyWith(activeColorSource: ThemeColorSource.preset));
  }
}
