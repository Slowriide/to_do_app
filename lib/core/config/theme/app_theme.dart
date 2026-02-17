import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_app/core/config/theme/app_colors.dart';

/// Defines the visual system for both light and dark modes.
class AppTheme {
  final bool isDarkMode;
  late final AppColors colors;
  AppTheme({required this.isDarkMode}) {
    colors = AppColors(isDarkMode);
  }

  ThemeData getTheme() => isDarkMode ? _darkTheme : _lightTheme;

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.onPrimary,
      brightness: brightness,
    ).copyWith(
      primary: colors.onPrimary,
      secondary: colors.secondary,
      surface: colors.surface,
      onSurface: colors.onSurface,
    );

    final baseText = GoogleFonts.notoSansTextTheme().apply(
      bodyColor: colors.text,
      displayColor: colors.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.surface,
      textTheme: baseText.copyWith(
        titleLarge: baseText.titleLarge?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          fontSize: 15,
          height: 1.35,
        ),
        bodySmall: baseText.bodySmall?.copyWith(
          fontSize: 13,
          height: 1.3,
          color: colors.tertiary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.primary,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: colors.tertiary.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.onPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: colors.tertiary),
        filled: true,
        fillColor: colors.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: colors.tertiary.withValues(alpha: 0.24),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: colors.tertiary.withValues(alpha: 0.24),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colors.onPrimary, width: 1.5),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        headerForegroundColor: colors.onSurface,
        dayStyle: TextStyle(color: colors.onSurface),
        todayBorder: BorderSide(color: colors.onPrimary),
        todayBackgroundColor: WidgetStatePropertyAll(
          colors.onPrimary.withValues(alpha: 0.12),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colors.surface,
        dialBackgroundColor: colors.surface2,
        hourMinuteColor: colors.surface2,
        hourMinuteTextColor: colors.onSurface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: TextStyle(color: colors.onSurface, fontSize: 13),
        decoration: BoxDecoration(
          color: colors.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.onPrimary.withValues(alpha: 0.15),
        iconTheme:
            WidgetStatePropertyAll(IconThemeData(color: colors.onSurface)),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.notoSans(
            color: colors.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  ThemeData get _lightTheme => _buildTheme(Brightness.light);
  ThemeData get _darkTheme => _buildTheme(Brightness.dark);
}
