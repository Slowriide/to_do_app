import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_app/core/config/theme/app_colors.dart';

/// A class that defines the application's theme based on the current mode (dark or light).
///
/// It provides methods to get the appropriate [ThemeData] for the application,
/// and defines text styles for various text elements in the app.
class AppTheme {
  final bool isDarkMode;
  late final AppColors colors;
  AppTheme({required this.isDarkMode}) {
    colors = AppColors(isDarkMode);
  }
  ThemeData getTheme() {
    return isDarkMode ? _darkTheme : _lightTheme;
  }

  final bodySmall = GoogleFonts.roboto()
      .copyWith(color: const Color.fromARGB(255, 236, 236, 236), fontSize: 18);
  final titleSmall = GoogleFonts.roboto().copyWith(fontSize: 20);

  ThemeData get _darkTheme => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: colors.surface,
        colorScheme: ColorScheme.dark(
          brightness: Brightness.dark,
          surface: colors.surface,
          onSurface: colors.onSurface,
          primary: colors.primary,
          onPrimary: colors.onPrimary,
          secondary: colors.secondary,
          tertiary: colors.tertiary,
        ),
        textTheme: TextTheme(
          titleLarge: GoogleFonts.roboto().copyWith(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
          titleMedium: GoogleFonts.roboto().copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w400,
            color: colors.text,
          ),
          titleSmall: GoogleFonts.roboto().copyWith(fontSize: 20),
          bodyLarge: GoogleFonts.roboto().copyWith(
              color: colors.text, fontSize: 25, fontWeight: FontWeight.w500),
          bodyMedium: GoogleFonts.roboto().copyWith(
              color: colors.text, fontSize: 19, fontWeight: FontWeight.w500),
          bodySmall:
              GoogleFonts.roboto().copyWith(color: colors.text, fontSize: 18),
          labelSmall:
              GoogleFonts.roboto().copyWith(color: colors.text, fontSize: 15),
          labelMedium: GoogleFonts.roboto().copyWith(
              color: colors.text, fontSize: 16, fontWeight: FontWeight.w600),
        ),

        //DATE PICKER
        datePickerTheme: DatePickerThemeData(
          cancelButtonStyle: TextButton.styleFrom(foregroundColor: colors.text),
          confirmButtonStyle:
              TextButton.styleFrom(foregroundColor: colors.text),
          dividerColor: Colors.transparent,
          headerHelpStyle: TextStyle(color: colors.text),
          headerForegroundColor: colors.text,
          backgroundColor: Color.fromARGB(255, 17, 17, 17),
          todayBorder: BorderSide(
            color: const Color.fromARGB(255, 64, 79, 165),
          ),
          todayBackgroundColor: WidgetStateProperty.all(colors.purple),
          yearStyle: TextStyle(color: colors.text),
          inputDecorationTheme: InputDecorationTheme(
            hintStyle: TextStyle(color: colors.text),
            labelStyle: TextStyle(color: colors.purple),
            focusColor: colors.text,
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.purple)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.purple, width: 2)),
          ),
        ),

        //TIME PICKER
        timePickerTheme: TimePickerThemeData(
          cancelButtonStyle: TextButton.styleFrom(foregroundColor: colors.text),
          confirmButtonStyle:
              TextButton.styleFrom(foregroundColor: colors.text),
          backgroundColor: Color.fromARGB(255, 17, 17, 17),
          dialBackgroundColor: Color.fromARGB(255, 17, 17, 17),
          hourMinuteColor: Color.fromARGB(210, 27, 27, 27),
          hourMinuteTextColor: colors.text,
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colors.purple, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Color.fromARGB(255, 17, 17, 17),
        ),

        //Tool tip
        tooltipTheme: TooltipThemeData(
          textStyle: bodySmall.copyWith(color: colors.text),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        navigationDrawerTheme: NavigationDrawerThemeData(
          iconTheme: WidgetStatePropertyAll(IconThemeData(color: colors.text)),
          labelTextStyle:
              WidgetStatePropertyAll(titleSmall.copyWith(color: colors.text)),
        ),
      );

  ThemeData get _lightTheme => ThemeData.light().copyWith(
        scaffoldBackgroundColor: colors.surface,
        colorScheme: ColorScheme.light(
          surface: colors.surface,
          onSurface: colors.onSurface,
          primary: colors.primary,
          onPrimary: colors.onPrimary,
          secondary: colors.secondary,
          tertiary: colors.tertiary,
          onTertiary: colors.text,
        ),
        textTheme: TextTheme(
          titleLarge: GoogleFonts.roboto().copyWith(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
          titleMedium: GoogleFonts.roboto().copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w400,
            color: colors.text,
          ),
          titleSmall: GoogleFonts.roboto().copyWith(fontSize: 20),
          bodyLarge: GoogleFonts.roboto().copyWith(
              color: colors.text, fontSize: 25, fontWeight: FontWeight.w500),
          bodyMedium: GoogleFonts.roboto().copyWith(
              color: colors.text, fontSize: 19, fontWeight: FontWeight.w500),
          bodySmall:
              GoogleFonts.roboto().copyWith(color: colors.text, fontSize: 18),
          labelSmall:
              GoogleFonts.roboto().copyWith(color: colors.text, fontSize: 15),
          labelMedium: GoogleFonts.roboto().copyWith(
              color: colors.text, fontSize: 16, fontWeight: FontWeight.w600),
        ),

        //DATE PICKER
        datePickerTheme: DatePickerThemeData(
          cancelButtonStyle: TextButton.styleFrom(foregroundColor: colors.text),
          confirmButtonStyle:
              TextButton.styleFrom(foregroundColor: colors.text),
          dividerColor: Colors.transparent,
          headerHelpStyle: TextStyle(color: colors.text),
          headerForegroundColor: colors.text,
          backgroundColor: colors.surface,
          todayBorder: BorderSide(
            color: Color(0xff7F5539),
          ),
          todayBackgroundColor: WidgetStateProperty.all(Color(0xff7F5539)),
          yearStyle: TextStyle(color: colors.text),
          inputDecorationTheme: InputDecorationTheme(
            hintStyle: TextStyle(color: colors.text),
            labelStyle: TextStyle(color: Color(0xff7F5539)),
            focusColor: colors.text,
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xff7F5539))),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xff7F5539), width: 2)),
          ),
        ),

        //TIME PICKER
        timePickerTheme: TimePickerThemeData(
          cancelButtonStyle: TextButton.styleFrom(foregroundColor: colors.text),
          confirmButtonStyle:
              TextButton.styleFrom(foregroundColor: colors.text),
          backgroundColor: colors.surface,
          dialBackgroundColor: Color(0xFFE6CCB2),
          hourMinuteColor: Color.fromARGB(210, 27, 27, 27),
          hourMinuteTextColor: colors.text,
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xff7F5539), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Color.fromARGB(255, 17, 17, 17),
        ),

        //Tool tip
        tooltipTheme: TooltipThemeData(
          textStyle: bodySmall.copyWith(color: colors.text),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        navigationDrawerTheme: NavigationDrawerThemeData(
          iconTheme: WidgetStatePropertyAll(IconThemeData(color: colors.text)),
          labelTextStyle:
              WidgetStatePropertyAll(titleSmall.copyWith(color: colors.text)),
        ),
      );
}
