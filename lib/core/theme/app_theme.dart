import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();
  static const background = Color(0xFF070A0F);
  static const surface = Color(0xFF0B1017);
  static const surfaceElevated = Color(0xFF111827);
  static const card = Color(0xFF0F1720);
  static const primary = Color(0xFF00E5A8);
  static const secondary = Color(0xFF00CFFF);
  static const accent = Color(0xFF8B5CF6);
  static const muted = Color(0xFF94A3B8);
  static const textPrimary = Color(0xFFF8FAFC);
  static const border = Color(0x1FFFFFFF);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);
  static const radius = 18.0;
  static const pagePadding = 18.0;

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(primary: primary, secondary: secondary, surface: surface, error: danger),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: textPrimary, displayColor: textPrimary),
      appBarTheme: const AppBarTheme(backgroundColor: background, elevation: 0, centerTitle: false),
      cardTheme: const CardThemeData(color: card, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radius)), side: BorderSide(color: border))),
      dividerTheme: const DividerThemeData(color: border, space: 1),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: surfaceElevated, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary)), labelStyle: const TextStyle(color: muted)),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: surface, indicatorColor: Color(0x3322E676), labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11)), height: 70),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14))),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: surfaceElevated, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    );
  }

  static ThemeData light() => ThemeData(useMaterial3: true, colorSchemeSeed: primary, brightness: Brightness.light);
}
