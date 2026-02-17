import 'package:flutter/material.dart';

/// A class that defines the color scheme for the application based on the current theme (dark or light).
class AppColors {
  final bool isDark;

  AppColors(this.isDark);

  Color get surface =>
      isDark ? const Color(0xFF11161C) : const Color(0xFFFFFBF2);
  Color get surface2 =>
      isDark ? const Color(0xFF1A222D) : const Color(0xFFFFF3D6);
  Color get onSurface =>
      isDark ? const Color(0xFFE6EDF5) : const Color(0xFF202124);
  Color get purple => const Color(0xFF1A73E8);
  Color get primary =>
      isDark ? const Color(0xFF202A36) : const Color(0xFFF1F3F4);
  Color get onPrimary =>
      isDark ? const Color(0xFF3B82F6) : const Color(0xFF1A73E8);
  Color get secondary =>
      isDark ? const Color(0xFF253243) : const Color(0xFFFAEFCB);
  Color get tertiary =>
      isDark ? const Color(0xFFA7B6C7) : const Color(0xFF5F6368);
  Color get onTertiary =>
      isDark ? const Color(0xFFDCE7F3) : const Color(0xFF202124);

  Color get text => onSurface;
}
