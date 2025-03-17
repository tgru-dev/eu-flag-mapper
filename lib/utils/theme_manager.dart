import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  late SharedPreferences _prefs;
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  ThemeManager() {
    _themeMode = ThemeMode.system;
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeKey, mode.toString());
    notifyListeners();
  }

  void toggleTheme() {
    final newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(newMode);
  }
} 