import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // ✅ Changed from static variables to static getters
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF2E7D32),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFA5D6A7),
      onPrimaryContainer: const Color(0xFF002109),
      secondary: const Color(0xFF546E7A),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFB0C4CF),
      tertiary: const Color(0xFFFFD54F),
      onTertiary: const Color(0xFF5B4B00),
      error: const Color(0xFFB00020),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF1A1C1E),
      outline: const Color(0xFF73787B),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.hovered)) return const Color(0xFF1B5E20);
          return const Color(0xFF2E7D32);
        }),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(0.0),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF73787B), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB0BEC5), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF546E7A)),
      hintStyle: const TextStyle(color: Color(0xFF90A4AE)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A1C1E),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1C1E),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF2E7D32),
      unselectedItemColor: const Color(0xFF73787B),
      elevation: 8,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      iconColor: const Color(0xFF2E7D32),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFFA5D6A7),
      onPrimary: const Color(0xFF002109),
      primaryContainer: const Color(0xFF3D8B40),
      onPrimaryContainer: Colors.white,
      secondary: const Color(0xFFB0C4CF),
      onSecondary: const Color(0xFF1C3B47),
      secondaryContainer: const Color(0xFF3E5A66),
      tertiary: const Color(0xFFE6C03D),
      onTertiary: const Color(0xFF332B00),
      error: const Color(0xFFCF6679),
      onError: const Color(0xFF600004),
      surface: const Color(0xFF121212),
      onSurface: Colors.white70,
      outline: const Color(0xFF90A4AE),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white70),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      color: const Color(0xFF1E1E1E),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.hovered)) return const Color(0xFF609966);
          return const Color(0xFFA5D6A7);
        }),
        foregroundColor: WidgetStateProperty.all(const Color(0xFF002109)),
        elevation: WidgetStateProperty.all(0.0),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF546E7A), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF455A64), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFA5D6A7), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF90A4AE)),
      hintStyle: const TextStyle(color: Color(0xFF78909C)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: const Color(0xFFA5D6A7),
      unselectedItemColor: const Color(0xFF78909C),
      elevation: 8,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      iconColor: const Color(0xFFA5D6A7),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF1E1E1E),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}