import 'package:flutter/material.dart';

@immutable
class ThemePreset {
  final String id;
  final String displayName;
  final Color seedColor;

  const ThemePreset({
    required this.id,
    required this.displayName,
    required this.seedColor,
  });
}

const List<ThemePreset> themePresets = [
  ThemePreset(
    id: 'oceanBlue',
    displayName: 'Ocean Blue',
    seedColor: Color(0xFF1A73E8),
  ),
  ThemePreset(
    id: 'forestGreen',
    displayName: 'Forest Green',
    seedColor: Color(0xFF2E7D32),
  ),
  ThemePreset(
    id: 'sunsetOrange',
    displayName: 'Sunset Orange',
    seedColor: Color(0xFFEF6C00),
  ),
  ThemePreset(
    id: 'roseRed',
    displayName: 'Rose Red',
    seedColor: Color(0xFFC62828),
  ),
  ThemePreset(
    id: 'violetIndigo',
    displayName: 'Violet Indigo',
    seedColor: Color(0xFF5E35B1),
  ),
];
