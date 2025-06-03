part of 'theme_cubit.dart';

/// State representing whether the current theme is dark mode or light mode.
///
/// Contains a single boolean value [isDarkmode] that indicates
/// if dark mode is enabled.
@immutable
class ThemeState extends Equatable {
  final bool isDarkmode;

  const ThemeState({
    required this.isDarkmode,
  });

  @override
  List<Object> get props => [isDarkmode];
}
