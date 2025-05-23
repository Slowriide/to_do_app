import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  final bool isDarkMode;
  AppTheme({required this.isDarkMode});
  ThemeData getTheme() {
    return isDarkMode ? _darkTheme : _lightTheme;
  }

  final Color surface = Color.fromARGB(255, 5, 5, 5);
  final Color surface2 = Color(0xff131318);
  final Color onSurface = Color(0xffE3E3E3);

  final Color purple = Color.fromARGB(255, 64, 79, 165);
  final Color primary = const Color.fromARGB(255, 29, 29, 29);
  final bodySmall = GoogleFonts.roboto()
      .copyWith(color: const Color.fromARGB(255, 236, 236, 236), fontSize: 18);
  final titleSmall = GoogleFonts.roboto().copyWith(fontSize: 20);

  ThemeData get _darkTheme => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: surface,
        colorScheme: ColorScheme.dark(
          brightness: Brightness.dark,
          surface: surface,
          onSurface: onSurface,
          primary: primary,
          onPrimary: purple,
          secondary: const Color.fromARGB(255, 17, 17, 17),
        ),
        textTheme: TextTheme(
          titleLarge: GoogleFonts.roboto().copyWith(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleMedium: GoogleFonts.roboto().copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          titleSmall: GoogleFonts.roboto().copyWith(fontSize: 20),
          bodyLarge: GoogleFonts.roboto().copyWith(
              color: Colors.white, fontSize: 25, fontWeight: FontWeight.w500),
          bodyMedium: GoogleFonts.roboto().copyWith(
              color: Colors.white, fontSize: 19, fontWeight: FontWeight.w500),
          bodySmall: bodySmall,
          labelSmall:
              GoogleFonts.roboto().copyWith(color: Colors.white, fontSize: 15),
          labelMedium: GoogleFonts.roboto().copyWith(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),

        //DATE PICKER
        datePickerTheme: DatePickerThemeData(
          cancelButtonStyle:
              TextButton.styleFrom(foregroundColor: Colors.white),
          confirmButtonStyle:
              TextButton.styleFrom(foregroundColor: Colors.white),
          dividerColor: Colors.transparent,
          headerHelpStyle: TextStyle(color: Colors.white),
          headerForegroundColor: Colors.white,
          backgroundColor: Color.fromARGB(255, 17, 17, 17),
          todayBorder: BorderSide(
            color: const Color.fromARGB(255, 64, 79, 165),
          ),
          todayBackgroundColor: WidgetStateProperty.all(purple),
          yearStyle: TextStyle(color: Colors.white),
          inputDecorationTheme: InputDecorationTheme(
            hintStyle: TextStyle(color: Colors.white),
            labelStyle: TextStyle(color: purple),
            focusColor: Colors.white,
            enabledBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: purple)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: purple, width: 2)),
          ),
        ),

        //TIME PICKER
        timePickerTheme: TimePickerThemeData(
          cancelButtonStyle:
              TextButton.styleFrom(foregroundColor: Colors.white),
          confirmButtonStyle:
              TextButton.styleFrom(foregroundColor: Colors.white),
          backgroundColor: Color.fromARGB(255, 17, 17, 17),
          dialBackgroundColor: Color.fromARGB(255, 17, 17, 17),
          hourMinuteColor: Color.fromARGB(210, 27, 27, 27),
          hourMinuteTextColor: Colors.white,
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: purple, width: 2),
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
          textStyle: bodySmall.copyWith(color: Colors.white),
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        navigationDrawerTheme: NavigationDrawerThemeData(
          iconTheme: WidgetStatePropertyAll(IconThemeData(color: Colors.white)),
          labelTextStyle:
              WidgetStatePropertyAll(titleSmall.copyWith(color: Colors.white)),
        ),
      );

  ThemeData get _lightTheme => ThemeData.light().copyWith(
        scaffoldBackgroundColor: surface,
        colorScheme: ColorScheme.light(
          surface: surface,
          onSurface: onSurface,
          primary: primary,
          onPrimary: purple,
          secondary: const Color.fromARGB(255, 17, 17, 17),
        ),
        textTheme: TextTheme(
          titleLarge: GoogleFonts.roboto().copyWith(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleMedium: GoogleFonts.roboto().copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          titleSmall: GoogleFonts.roboto().copyWith(fontSize: 20),
          bodyLarge: GoogleFonts.roboto().copyWith(
              color: Colors.white, fontSize: 25, fontWeight: FontWeight.w500),
          bodyMedium: GoogleFonts.roboto().copyWith(
              color: Colors.white, fontSize: 19, fontWeight: FontWeight.w500),
          bodySmall: bodySmall,
          labelSmall:
              GoogleFonts.roboto().copyWith(color: Colors.white, fontSize: 15),
          labelMedium: GoogleFonts.roboto().copyWith(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),

        //DATE PICKER
        datePickerTheme: DatePickerThemeData(
          cancelButtonStyle:
              TextButton.styleFrom(foregroundColor: Colors.white),
          confirmButtonStyle:
              TextButton.styleFrom(foregroundColor: Colors.white),
          dividerColor: Colors.transparent,
          headerHelpStyle: TextStyle(color: Colors.white),
          headerForegroundColor: Colors.white,
          backgroundColor: Color.fromARGB(255, 17, 17, 17),
          todayBorder: BorderSide(
            color: const Color.fromARGB(255, 64, 79, 165),
          ),
          todayBackgroundColor: WidgetStateProperty.all(purple),
          yearStyle: TextStyle(color: Colors.white),
          inputDecorationTheme: InputDecorationTheme(
            hintStyle: TextStyle(color: Colors.white),
            labelStyle: TextStyle(color: purple),
            focusColor: Colors.white,
            enabledBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: purple)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: purple, width: 2)),
          ),
        ),

        //TIME PICKER
        timePickerTheme: TimePickerThemeData(
          cancelButtonStyle:
              TextButton.styleFrom(foregroundColor: Colors.white),
          confirmButtonStyle:
              TextButton.styleFrom(foregroundColor: Colors.white),
          backgroundColor: Color.fromARGB(255, 17, 17, 17),
          dialBackgroundColor: Color.fromARGB(255, 17, 17, 17),
          hourMinuteColor: Color.fromARGB(210, 27, 27, 27),
          hourMinuteTextColor: Colors.white,
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: purple, width: 2),
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
          textStyle: bodySmall.copyWith(color: Colors.white),
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        navigationDrawerTheme: NavigationDrawerThemeData(
          iconTheme: WidgetStatePropertyAll(IconThemeData(color: Colors.white)),
          labelTextStyle:
              WidgetStatePropertyAll(titleSmall.copyWith(color: Colors.white)),
        ),
      );
}
