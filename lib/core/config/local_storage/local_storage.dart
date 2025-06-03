import 'package:shared_preferences/shared_preferences.dart';

/// A utility class for managing persistent key-value storage using SharedPreferences.
///
/// This class exposes static getters and setters for app preferences, such as theme mode.
///
/// Call [configurePrefs] once during app initialization to load the SharedPreferences instance.
class LocalStorage {
  static late SharedPreferences prefs;

  static Future<void> configurePrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  static bool get isDarkMode => prefs.getBool('isDarkMode') ?? false;
  static set isDarkMode(bool value) => prefs.setBool('isDarkMode', value);
}
