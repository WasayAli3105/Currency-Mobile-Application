import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:curren_see/Constants/Constants.dart';

class AppTheme {
  //LIGHT THEME
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: gold,
    scaffoldBackgroundColor: lightBg,
    canvasColor: lightBg,
    cardColor: lightCard,

    colorScheme: const ColorScheme.light(
      primary: gold,
      secondary: goldDark,
      surface: lightCard,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: lightBg,
      foregroundColor: lightTextPrimary,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: lightTextPrimary),
      titleTextStyle: TextStyle(
        color: lightTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: lightTextPrimary, fontSize: 28, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: lightTextPrimary, fontSize: 22, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: lightTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: lightTextPrimary, fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: lightTextPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: lightTextGrey, fontSize: 14),
      bodySmall: TextStyle(color: lightTextGrey, fontSize: 12),
      labelLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: Colors.white,
        elevation: 3,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightInputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: const TextStyle(color: lightTextGrey, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightInputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightInputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: gold, width: 2),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightCard,
      selectedItemColor: gold,
      unselectedItemColor: lightTextGrey,
      type: BottomNavigationBarType.fixed,
    ),

    iconTheme: const IconThemeData(color: lightIcon, size: 24),
    dividerTheme: const DividerThemeData(color: lightDivider, thickness: 1),
  );

  // DARK THEME
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: gold,
    scaffoldBackgroundColor: darkBg,
    canvasColor: darkBg,
    cardColor: darkCard,

    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: goldLight,
      surface: darkCard,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: darkTextPrimary,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      foregroundColor: gold,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: gold),
      titleTextStyle: TextStyle(
        color: gold,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: gold, fontSize: 28, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: darkTextPrimary, fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: darkTextPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: darkTextGrey, fontSize: 14),
      bodySmall: TextStyle(color: darkTextGrey, fontSize: 12),
      labelLarge: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: Colors.black,
        elevation: 4,
        shadowColor: goldShadow40,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkInputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: const TextStyle(color: darkTextGrey, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: goldBorder30),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: goldBorder30),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: gold, width: 2),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkCard,
      selectedItemColor: gold,
      unselectedItemColor: darkTextGrey,
      type: BottomNavigationBarType.fixed,
    ),

    iconTheme: const IconThemeData(color: gold, size: 24),
    dividerTheme: const DividerThemeData(color: darkDivider, thickness: 1),
  );
}