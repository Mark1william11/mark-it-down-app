// lib/presentation/theme/app_theme.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _primaryColor = Color(0xFF5E35B1);
const _secondaryColor = Color(0xFFF06292);

const _lightScaffoldColorTop = Color(0xFFF3E5F5);
const _lightScaffoldColorBottom = Color(0xFFEDE7F6);
const _lightCardColor = Colors.white;

const _darkScaffoldColorTop = Color(0xFF1A1A2E);
const _darkScaffoldColorBottom = Color(0xFF16213E);
const _darkCardColor = Color(0xFF2C2C4E);

class AppTheme {
  static final _baseFont = GoogleFonts.poppinsTextTheme();

  static const Color highPriorityColor = Color(0xFFE53935);
  static const Color mediumPriorityColor = Color(0xFFFB8C00);
  static const Color lowPriorityColor = Color(0xFF1E88E5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: _lightScaffoldColorBottom,
      colorScheme: const ColorScheme.light(
        primary: _primaryColor,
        secondary: _secondaryColor,
        background: _lightScaffoldColorBottom,
        surface: _lightCardColor,
        onSurface: Colors.black87,
        error: highPriorityColor,
      ),
      cardTheme: CardThemeData( // <-- This is the corrected line from before
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      textTheme: _baseFont.apply(bodyColor: Colors.black87),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        titleTextStyle: _baseFont.titleLarge?.copyWith(color: Colors.black87),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: _darkScaffoldColorBottom,
      colorScheme: const ColorScheme.dark(
        primary: _primaryColor,
        secondary: _secondaryColor,
        background: _darkScaffoldColorBottom,
        surface: _darkCardColor,
        onSurface: Colors.white,
        error: highPriorityColor,
      ),
      cardTheme: CardThemeData( // <-- This is the corrected line from before
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      textTheme: _baseFont.apply(bodyColor: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkCardColor.withOpacity(0.85),
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
        titleTextStyle: _baseFont.titleLarge?.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _secondaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  static LinearGradient get lightGradient {
    return const LinearGradient(
      colors: [_lightScaffoldColorTop, _lightScaffoldColorBottom],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static LinearGradient get darkGradient {
    return const LinearGradient(
      colors: [_darkScaffoldColorTop, _darkScaffoldColorBottom],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}