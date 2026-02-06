import 'package:flutter/material.dart';

// NOTE: Colors were OKLCH initially so that's why ARGB is being used.
class AppColors {
  // light theme
  static const Color lightBgDark = Color(0xFFE8E1F0);
  static const Color lightBg = Color(0xFFF5F3F9);
  static const Color lightBgLight = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF2D1F3D);
  static const Color lightTextMuted = Color(0xFF70607B);
  static const Color lightHighlight = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFF9A8BA5);
  static const Color lightBorderMuted = Color(0xFFB5A8BE);
  static const Color lightPrimary = Color(0xFF6B5877);
  static const Color lightSecondary = Color(0xFF5C6B50);
  static const Color lightDanger = Color(0xFF9F5D4A);
  static const Color lightWarning = Color(0xFF9F8D3D);
  static const Color lightSuccess = Color(0xFF4A9F6E);
  static const Color lightInfo = Color(0xFF5C66B8);

  // dark theme
  static const Color darkBgDark = Color(0xFF1A0F26);
  static const Color darkBg = Color(0xFF281A38);
  static const Color darkBgLight = Color(0xFF36254A);
  static const Color darkText = Color(0xFFF5F3F9);
  static const Color darkTextMuted = Color(0xFFC5B8D1);
  static const Color darkHighlight = Color(0xFF8B75A1);
  static const Color darkBorder = Color(0xFF6B5877);
  static const Color darkBorderMuted = Color(0xFF4D3F5E);
  static const Color darkPrimary = Color(0xFFC5B8D1);
  static const Color darkSecondary = Color(0xFFB8D1A6);
  static const Color darkDanger = Color(0xFFD18F7A);
  static const Color darkWarning = Color(0xFFD1BB6E);
  static const Color darkSuccess = Color(0xFF7AD1A0);
  static const Color darkInfo = Color(0xFF9AA6E8);
}

/// Application theme configuration with light and dark variants
class AppTheme {
  // Seed color based on the primary purple from the original design
  static const Color _seedColor = Color(0xFF6B5877);

  /// Light theme for the application
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      surface: AppColors.lightBg,
    ),
    scaffoldBackgroundColor: AppColors.lightBg,
    appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 0),
    cardTheme: const CardThemeData(elevation: 0, clipBehavior: Clip.antiAlias),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 65,
      elevation: 0,
      indicatorColor: _seedColor.withValues(alpha: 0.1),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );

  /// Dark theme for the application
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      surface: AppColors.darkBg,
    ),
    scaffoldBackgroundColor: AppColors.darkBg,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.darkBg,
    ),
    cardTheme: const CardThemeData(elevation: 0, clipBehavior: Clip.antiAlias),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkBgLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 65,
      elevation: 0,
      indicatorColor: _seedColor.withValues(alpha: 0.3),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}

// Extension to get colors from context
extension ThemeColors on BuildContext {
  Color get bgDark => Theme.of(this).brightness == Brightness.light
      ? AppColors.lightBgDark
      : AppColors.darkBgDark;

  Color get bg => Theme.of(this).colorScheme.surface;

  Color get bgLight => Theme.of(this).brightness == Brightness.light
      ? AppColors.lightBgLight
      : AppColors.darkBgLight;

  Color get text => Theme.of(this).colorScheme.onSurface;

  Color get textMuted => Theme.of(this).brightness == Brightness.light
      ? AppColors.lightTextMuted
      : AppColors.darkTextMuted;

  Color get highlight => Theme.of(this).brightness == Brightness.light
      ? AppColors.lightHighlight
      : AppColors.darkHighlight;

  Color get border => Theme.of(this).colorScheme.outline;

  Color get borderMuted => Theme.of(this).brightness == Brightness.light
      ? AppColors.lightBorderMuted
      : AppColors.darkBorderMuted;

  Color get primary => Theme.of(this).colorScheme.primary;

  Color get secondary => Theme.of(this).colorScheme.secondary;

  Color get danger => Theme.of(this).colorScheme.error;

  Color get warning => Theme.of(this).brightness == Brightness.light
      ? AppColors.lightWarning
      : AppColors.darkWarning;

  Color get success => Theme.of(this).brightness == Brightness.light
      ? AppColors.lightSuccess
      : AppColors.darkSuccess;

  Color get info => Theme.of(this).brightness == Brightness.light
      ? AppColors.lightInfo
      : AppColors.darkInfo;
}
