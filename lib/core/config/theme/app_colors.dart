import 'package:flutter/material.dart';

/// A class that defines the color scheme for the application based on the current theme (dark or light).
class AppColors {
  final bool isDark;

  AppColors(this.isDark);

  Color get surface =>
      isDark ? Color.fromARGB(255, 5, 5, 5) : Color(0xffEDE0D4);
  Color get surface2 => isDark ? Color(0xFF131318) : Color(0xffEDEDE9);
  Color get onSurface => isDark ? Color(0xFFE3E3E3) : Color(0xff7F5539);
  Color get purple => Color.fromARGB(255, 64, 79, 165);
  Color get primary =>
      isDark ? Color.fromARGB(255, 29, 29, 29) : Color(0xFFB08968);
  Color get onPrimary =>
      isDark ? Color.fromARGB(255, 64, 79, 165) : Color(0xFFDDB892);
  Color get secondary =>
      isDark ? Color.fromARGB(255, 17, 17, 17) : Color(0xFFE6CCB2);
  Color get tertiary =>
      isDark ? Color.fromARGB(213, 158, 158, 158) : Color(0xFFE6CCB2);
  Color get onTertiary => isDark ? Color(0xFFE3E3E3) : Color(0xFFE6CCB2);

  Color get text => isDark ? Colors.white : Color(0xff7F5539);
}
