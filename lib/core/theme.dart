import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
/// Colours from app/globals.css (@theme tokens).
class C {
  static const paper = Color(0xFFE7EDDA);
  static const paperDeep = Color(0xFFD6E0C5);
  static const card = Color(0xFFF7F9EF);
  static const ink = Color(0xFF1E2B37);
  static const inkSoft = Color(0xFF4A5966);
  static const hwy = Color(0xFFF3B32A);
  static const sign = Color(0xFF175089);
  static const signDeep = Color(0xFF0F3A68);
  static const route = Color(0xFFCC4437);
  static const park = Color(0xFF5E9A5B);

  static Color tone(String t) {
    switch (t) {
      case 'red':
        return route;
      case 'yellow':
        return hwy;
      case 'green':
        return park;
      case 'ink':
        return ink;
      default:
        return sign;
    }
  }

  /// Text colour that stays readable on a tone.
  static Color onTone(String t) => t == 'yellow' ? ink : Colors.white;
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: C.sign,
    brightness: Brightness.light,
  ).copyWith(
    primary: C.sign,
    secondary: C.hwy,
    surface: C.paper,
    error: C.route,
  );
  OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.paper,
    // Native Android page transition (zoom / predictive back friendly).
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    appBarTheme: const AppBarTheme(
      backgroundColor: C.paper,
      foregroundColor: C.ink,
      elevation: 0,
      scrolledUnderElevation: 3,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: border(scheme.outline, 1),
      enabledBorder: border(scheme.outline, 1),
      focusedBorder: border(C.sign, 2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.card,
      indicatorColor: C.hwy,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
