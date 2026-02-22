import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/config/theme/theme_presets.dart';

part 'theme_state.dart';

enum ThemeColorSource { preset, custom }
enum ThemeBackgroundSource { preset, custom }

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
    final customBackground = _normalizeHex(LocalStorage.customBackgroundHex);
    final backgroundSource =
        _parseBackgroundSource(LocalStorage.backgroundColorSource);
    final effectiveSource =
        source == ThemeColorSource.custom && custom == null
            ? ThemeColorSource.preset
            : source;
    final effectiveBackgroundSource =
        backgroundSource == ThemeBackgroundSource.custom &&
                customBackground == null
            ? ThemeBackgroundSource.preset
            : backgroundSource;
    return ThemeState(
      isDarkmode: LocalStorage.isDarkMode,
      presetId: _resolvePresetId(LocalStorage.themePresetId),
      customColorHex: custom,
      activeColorSource: effectiveSource,
      backgroundPresetId:
          _resolveBackgroundPresetId(LocalStorage.backgroundPresetId),
      customBackgroundHex: customBackground,
      activeBackgroundSource: effectiveBackgroundSource,
    );
  }

  static ThemeColorSource _parseSource(String raw) {
    return raw == ThemeColorSource.custom.name
        ? ThemeColorSource.custom
        : ThemeColorSource.preset;
  }

  static ThemeBackgroundSource _parseBackgroundSource(String raw) {
    return raw == ThemeBackgroundSource.custom.name
        ? ThemeBackgroundSource.custom
        : ThemeBackgroundSource.preset;
  }

  static String _resolvePresetId(String value) {
    final exists = themePresets.any((preset) => preset.id == value);
    if (exists) return value;
    return themePresets.first.id;
  }

  static String _resolveBackgroundPresetId(String value) {
    final exists =
        backgroundPresets.any((backgroundPreset) => backgroundPreset.id == value);
    if (exists) return value;
    return backgroundPresets.first.id;
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

  void selectBackgroundPreset(String backgroundPresetId) {
    final resolvedPresetId = _resolveBackgroundPresetId(backgroundPresetId);
    LocalStorage.backgroundPresetId = resolvedPresetId;
    LocalStorage.backgroundColorSource = ThemeBackgroundSource.preset.name;
    emit(
      state.copyWith(
        backgroundPresetId: resolvedPresetId,
        activeBackgroundSource: ThemeBackgroundSource.preset,
      ),
    );
  }

  bool setCustomBackgroundHex(String hex) {
    final normalized = _normalizeHex(hex);
    if (normalized == null) return false;

    LocalStorage.customBackgroundHex = normalized;
    LocalStorage.backgroundColorSource = ThemeBackgroundSource.custom.name;
    emit(
      state.copyWith(
        customBackgroundHex: normalized,
        activeBackgroundSource: ThemeBackgroundSource.custom,
      ),
    );
    return true;
  }

  void clearCustomBackground() {
    LocalStorage.backgroundColorSource = ThemeBackgroundSource.preset.name;
    emit(
      state.copyWith(
        activeBackgroundSource: ThemeBackgroundSource.preset,
      ),
    );
  }
}
