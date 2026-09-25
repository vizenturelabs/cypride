import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData buildLightTheme({ColorScheme? dynamicScheme}) {
    final isDynamic = dynamicScheme != null;
    final scheme = dynamicScheme ?? const ColorScheme.light(
      primary: Color(0xFF2E7D32),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFA5D6A7),
      onPrimaryContainer: Color(0xFF002109),
      secondary: Color(0xFF546E7A),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFB0C4CF),
      tertiary: Color(0xFFFFD54F),
      onTertiary: Color(0xFF5B4B00),
      error: Color(0xFFB00020),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1A1C1E),
      outline: Color(0xFF73787B),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
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
            if (isDynamic) {
              return states.contains(WidgetState.hovered) ? scheme.primaryContainer : scheme.primary;
            }
            if (states.contains(WidgetState.hovered)) return const Color(0xFF1B5E20);
            return const Color(0xFF2E7D32);
          }),
          foregroundColor: WidgetStateProperty.all(isDynamic ? scheme.onPrimary : Colors.white),
          elevation: WidgetStateProperty.all(0.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDynamic ? scheme.outline : const Color(0xFF73787B), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDynamic ? scheme.outline.withAlpha(128) : const Color(0xFFB0BEC5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDynamic ? scheme.primary : const Color(0xFF2E7D32), width: 2),
        ),
        labelStyle: TextStyle(color: isDynamic ? scheme.onSurface.withAlpha(178) : const Color(0xFF546E7A)),
        hintStyle: TextStyle(color: isDynamic ? scheme.onSurface.withAlpha(128) : const Color(0xFF90A4AE)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDynamic ? scheme.surface : Colors.white,
        foregroundColor: isDynamic ? scheme.onSurface : const Color(0xFF1A1C1E),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDynamic ? scheme.onSurface : const Color(0xFF1A1C1E),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDynamic ? scheme.surface : Colors.white,
        selectedItemColor: isDynamic ? scheme.primary : const Color(0xFF2E7D32),
        unselectedItemColor: isDynamic ? scheme.onSurface.withAlpha(153) : const Color(0xFF73787B),
        elevation: 8,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        iconColor: isDynamic ? scheme.primary : const Color(0xFF2E7D32),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDynamic ? scheme.surface : Colors.white,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData buildDarkTheme({ColorScheme? dynamicScheme, bool isAmoled = false}) {
    final isDynamic = dynamicScheme != null;
    final scheme = dynamicScheme ?? const ColorScheme.dark(
      primary: Color(0xFFA5D6A7),
      onPrimary: Color(0xFF002109),
      primaryContainer: Color(0xFF3D8B40),
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFFB0C4CF),
      onSecondary: Color(0xFF1C3B47),
      secondaryContainer: Color(0xFF3E5A66),
      tertiary: Color(0xFFE6C03D),
      onTertiary: Color(0xFF332B00),
      error: Color(0xFFCF6679),
      onError: Color(0xFF600004),
      surface: Color(0xFF121212),
      onSurface: Colors.white70,
      outline: Color(0xFF90A4AE),
    );

    final Color bgColor = isAmoled ? Colors.black : (isDynamic ? scheme.surface : const Color(0xFF121212));
    final Color appBarBg = isAmoled ? Colors.black : (isDynamic ? scheme.surface : const Color(0xFF1E1E1E));
    final Color cardColor = isAmoled ? const Color(0xFF121212) : const Color(0xFF1E1E1E);
    final Color bottomNavBg = isAmoled ? Colors.black : (isDynamic ? scheme.surface : const Color(0xFF1E1E1E));
    final Color dialogBg = isAmoled ? const Color(0xFF121212) : const Color(0xFF1E1E1E);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(surface: bgColor),
      scaffoldBackgroundColor: bgColor,
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: isDynamic ? scheme.onSurface : Colors.white70),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: isDynamic ? scheme.onSurface : Colors.white),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDynamic ? scheme.onSurface : Colors.white),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDynamic ? scheme.onSurface : Colors.white),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        color: cardColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (isDynamic) {
              return states.contains(WidgetState.hovered) ? scheme.primaryContainer : scheme.primary;
            }
            if (states.contains(WidgetState.hovered)) return const Color(0xFF609966);
            return const Color(0xFFA5D6A7);
          }),
          foregroundColor: WidgetStateProperty.all(isDynamic ? scheme.onPrimary : const Color(0xFF002109)),
          elevation: WidgetStateProperty.all(0.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDynamic ? scheme.outline : const Color(0xFF546E7A), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDynamic ? scheme.outline.withAlpha(128) : const Color(0xFF455A64), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDynamic ? scheme.primary : const Color(0xFFA5D6A7), width: 2),
        ),
        labelStyle: TextStyle(color: isDynamic ? scheme.onSurface.withAlpha(178) : const Color(0xFF90A4AE)),
        hintStyle: TextStyle(color: isDynamic ? scheme.onSurface.withAlpha(128) : const Color(0xFF78909C)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: isDynamic ? scheme.onSurface : Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDynamic ? scheme.onSurface : Colors.white,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bottomNavBg,
        selectedItemColor: isDynamic ? scheme.primary : const Color(0xFFA5D6A7),
        unselectedItemColor: isDynamic ? scheme.onSurface.withAlpha(153) : const Color(0xFF78909C),
        elevation: 8,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        iconColor: isDynamic ? scheme.primary : const Color(0xFFA5D6A7),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: dialogBg,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}