part of 'theme_cubit.dart';

/// State representing whether the current theme is dark mode or light mode.
@immutable
class ThemeState extends Equatable {
  final bool isDarkmode;
  final String presetId;
  final String? customColorHex;
  final ThemeColorSource activeColorSource;
  final String backgroundPresetId;
  final String? customBackgroundHex;
  final ThemeBackgroundSource activeBackgroundSource;

  const ThemeState({
    required this.isDarkmode,
    required this.presetId,
    required this.customColorHex,
    required this.activeColorSource,
    required this.backgroundPresetId,
    required this.customBackgroundHex,
    required this.activeBackgroundSource,
  });

  ThemeState copyWith({
    bool? isDarkmode,
    String? presetId,
    String? customColorHex,
    ThemeColorSource? activeColorSource,
    String? backgroundPresetId,
    String? customBackgroundHex,
    ThemeBackgroundSource? activeBackgroundSource,
  }) {
    return ThemeState(
      isDarkmode: isDarkmode ?? this.isDarkmode,
      presetId: presetId ?? this.presetId,
      customColorHex: customColorHex ?? this.customColorHex,
      activeColorSource: activeColorSource ?? this.activeColorSource,
      backgroundPresetId: backgroundPresetId ?? this.backgroundPresetId,
      customBackgroundHex: customBackgroundHex ?? this.customBackgroundHex,
      activeBackgroundSource:
          activeBackgroundSource ?? this.activeBackgroundSource,
    );
  }

  @override
  List<Object?> get props => [
        isDarkmode,
        presetId,
        customColorHex,
        activeColorSource,
        backgroundPresetId,
        customBackgroundHex,
        activeBackgroundSource,
      ];
}
