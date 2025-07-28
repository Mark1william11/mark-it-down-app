// lib/presentation/notifiers/theme_notifier.dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_notifier.g.dart';

// THE FIX: The class now correctly extends _$AppTheme, which the generator
// will make into a subclass of AutoDisposeAsyncNotifier.
@riverpod
class AppTheme extends _$AppTheme {
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    // Use the new key, but check the old key ('themeMode') for backward compatibility
    // and default to system if neither exists.
    final themeIndex = prefs.getInt('app_theme_mode') ?? prefs.getInt('themeMode') ?? ThemeMode.system.index;
    return ThemeMode.values[themeIndex];
  }

  Future<void> toggleTheme() async {
    // Get the current theme, but default to light if it's system or null
    final currentTheme = state.valueOrNull ?? ThemeMode.light;
    
    // THE FIX: A simple binary toggle.
    // If the current theme is dark, switch to light. Otherwise, switch to dark.
    final newTheme = currentTheme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    
    final prefs = await SharedPreferences.getInstance();
    // We save the explicit theme, not 'system'.
    // We'll also change the key to avoid conflicts with the old logic.
    await prefs.setInt('app_theme_mode', newTheme.index);

    // Update the state
    state = AsyncData(newTheme);
  }
}