part of 'theme_cubit.dart';

/// State representing whether the current theme is dark mode or light mode.
@immutable
class ThemeState extends Equatable {
  final bool isDarkmode;
  final String presetId;
  final String? customColorHex;
  final ThemeColorSource activeColorSource;

  const ThemeState({
    required this.isDarkmode,
    required this.presetId,
    required this.customColorHex,
    required this.activeColorSource,
  });

  ThemeState copyWith({
    bool? isDarkmode,
    String? presetId,
    String? customColorHex,
    ThemeColorSource? activeColorSource,
  }) {
    return ThemeState(
      isDarkmode: isDarkmode ?? this.isDarkmode,
      presetId: presetId ?? this.presetId,
      customColorHex: customColorHex ?? this.customColorHex,
      activeColorSource: activeColorSource ?? this.activeColorSource,
    );
  }

  @override
  List<Object?> get props => [
        isDarkmode,
        presetId,
        customColorHex,
        activeColorSource,
      ];
}
