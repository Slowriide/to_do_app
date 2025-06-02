import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static late SharedPreferences prefs;

  static Future<void> configurePrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  static bool get isDarkMode => prefs.getBool('isDarkMode') ?? false;
  static set isDarkMode(bool value) => prefs.setBool('isDarkMode', value);
}
