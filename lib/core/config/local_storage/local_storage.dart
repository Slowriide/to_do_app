import 'package:shared_preferences/shared_preferences.dart';

/// A utility class for managing persistent key-value storage using SharedPreferences.
///
/// This class exposes static getters and setters for app preferences, such as theme mode.
///
/// Call [configurePrefs] once during app initialization to load the SharedPreferences instance.
class LocalStorage {
  static late SharedPreferences prefs;
  static const String _isDarkModeKey = 'isDarkMode';
  static const String _themePresetIdKey = 'themePresetId';
  static const String _themeColorSourceKey = 'themeColorSource';
  static const String _customThemeHexKey = 'customThemeHex';

  static Future<void> configurePrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  static bool get isDarkMode => prefs.getBool(_isDarkModeKey) ?? false;
  static set isDarkMode(bool value) => prefs.setBool(_isDarkModeKey, value);

  static String get themePresetId => prefs.getString(_themePresetIdKey) ?? 'oceanBlue';
  static set themePresetId(String value) => prefs.setString(_themePresetIdKey, value);

  static String get themeColorSource => prefs.getString(_themeColorSourceKey) ?? 'preset';
  static set themeColorSource(String value) =>
      prefs.setString(_themeColorSourceKey, value);

  static String? get customThemeHex => prefs.getString(_customThemeHexKey);
  static set customThemeHex(String? value) {
    if (value == null) {
      prefs.remove(_customThemeHexKey);
      return;
    }
    prefs.setString(_customThemeHexKey, value);
  }
}
