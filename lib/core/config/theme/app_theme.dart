import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_app/core/config/theme/theme_presets.dart';

/// Defines the visual system for both light and dark modes.
class AppTheme {
  final bool isDarkMode;
  final String presetId;
  final String? customColorHex;
  final bool useCustomColor;
  AppTheme({
    required this.isDarkMode,
    this.presetId = 'oceanBlue',
    this.customColorHex,
    this.useCustomColor = false,
  });

  ThemeData getTheme() => isDarkMode ? _darkTheme : _lightTheme;

  ThemeData _buildTheme(Brightness brightness) {
    final seedColor = _resolveSeedColor();
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ).copyWith(
      onInverseSurface: brightness == Brightness.dark
          ? const Color(0xFF1A222D)
          : const Color(0xFFFFF3D6),
    );

    final baseText = GoogleFonts.notoSansTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: baseText.copyWith(
        titleLarge: baseText.titleLarge?.copyWith(
          fontSize: 28,
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
          color: scheme.onSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.dark
            ? scheme.primaryContainer.withValues(alpha: 0.28)
            : scheme.primaryContainer.withValues(alpha: 0.44),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: scheme.tertiary.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: scheme.tertiary),
        filled: true,
        fillColor: scheme.primaryContainer.withValues(alpha: 0.55),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: scheme.tertiary.withValues(alpha: 0.26),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: scheme.tertiary.withValues(alpha: 0.26),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: scheme.primary.withValues(alpha: 0.95),
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.tertiary.withValues(alpha: 0.35);
            }
            if (states.contains(WidgetState.pressed)) {
              return scheme.primary.withValues(alpha: 0.85);
            }
            if (states.contains(WidgetState.hovered)) {
              return scheme.primary.withValues(alpha: 0.92);
            }
            return scheme.primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.pressed)) return 0;
            if (states.contains(WidgetState.hovered)) return 2;
            return 0;
          }),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 15,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.onInverseSurface.withValues(alpha: 0.78),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: scheme.tertiary.withValues(alpha: 0.24),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: scheme.tertiary.withValues(alpha: 0.24),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: scheme.primary.withValues(alpha: 0.95),
              width: 1.4,
            ),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
              scheme.onInverseSurface.withValues(alpha: 0.98)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.tertiary.withValues(alpha: 0.25)),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        headerForegroundColor: scheme.onSurface,
        dayStyle: TextStyle(color: scheme.onSurface),
        todayBorder: BorderSide(color: scheme.primary),
        todayBackgroundColor: WidgetStatePropertyAll(
          scheme.primary.withValues(alpha: 0.12),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: scheme.surface,
        dialBackgroundColor: scheme.onInverseSurface,
        hourMinuteColor: scheme.onInverseSurface,
        hourMinuteTextColor: scheme.onSurface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
        decoration: BoxDecoration(
          color: scheme.onInverseSurface,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.15),
        iconTheme:
            WidgetStatePropertyAll(IconThemeData(color: scheme.onSurface)),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.notoSans(
            color: scheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _resolveSeedColor() {
    if (useCustomColor) {
      final customColor = _parseHexColor(customColorHex);
      if (customColor != null) return customColor;
    }
    final preset = themePresets.where((item) => item.id == presetId);
    if (preset.isNotEmpty) return preset.first.seedColor;
    return themePresets.first.seedColor;
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null) return null;
    final value = hex.trim();
    if (value.isEmpty) return null;
    final normalized = value.startsWith('#') ? value.substring(1) : value;
    if (normalized.length != 6) return null;
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) return null;
    return Color(0xFF000000 | parsed);
  }

  ThemeData get _lightTheme => _buildTheme(Brightness.light);
  ThemeData get _darkTheme => _buildTheme(Brightness.dark);
}
