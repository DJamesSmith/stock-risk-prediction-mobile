import 'package:flutter/material.dart';

class AppColors {
  static const Color seed = Color(0xFF0E7490);
  static const Color low = Color(0xFF2E7D32);
  static const Color medium = Color(0xFFF9A825);
  static const Color high = Color(0xFFC62828);
  static const Color notRated = Color(0xFF757575);
  static const Color up = Color(0xFF2E7D32);
  static const Color down = Color(0xFFC62828);
  static const Color live = Color(0xFF2E7D32);
  static const Color reconnecting = Color(0xFFF9A825);
  static const Color offline = Color(0xFF9E9E9E);

  static Color riskColor(String? label) {
    if (label == 'low') {
      return low;
    }

    if (label == 'medium') {
      return medium;
    }

    if (label == 'high') {
      return high;
    }

    return notRated;
  }

  static Color riskTextColor(String? label) {
    if (label == 'medium') {
      return Colors.black;
    }

    return Colors.white;
  }

  static Color gainColor(double? value) {
    if (value == null || value == 0) {
      return notRated;
    }

    return value > 0 ? up : down;
  }
}

class AppTheme {
  static ThemeData light() {
    return _build(Brightness.light);
  }

  static ThemeData dark() {
    return _build(Brightness.dark);
  }

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
