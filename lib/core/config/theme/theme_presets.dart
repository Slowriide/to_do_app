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

@immutable
class BackgroundPreset {
  final String id;
  final String displayName;
  final Color color;

  const BackgroundPreset({
    required this.id,
    required this.displayName,
    required this.color,
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

const List<BackgroundPreset> backgroundPresets = [
  BackgroundPreset(
    id: 'paper',
    displayName: 'Paper',
    color: Color(0xFFF7F7F5),
  ),
  BackgroundPreset(
    id: 'mist',
    displayName: 'Mist',
    color: Color(0xFFEFF4F8),
  ),
  BackgroundPreset(
    id: 'sand',
    displayName: 'Sand',
    color: Color(0xFFF9F1E3),
  ),
  BackgroundPreset(
    id: 'sage',
    displayName: 'Sage',
    color: Color(0xFFEAF3EC),
  ),
  BackgroundPreset(
    id: 'slate',
    displayName: 'Slate',
    color: Color(0xFF161D28),
  ),
  BackgroundPreset(
    id: 'charcoal',
    displayName: 'Charcoal',
    color: Color(0xFF111315),
  ),
];
