import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _dynamicKey = 'use_dynamic_colors';
  static const String _amoledKey = 'use_amoled';

  ThemeMode _themeMode = ThemeMode.system;
  bool _useDynamicColors = false;
  bool _useAmoled = false;

  ThemeMode get themeMode => _themeMode;
  bool get useDynamicColors => _useDynamicColors;
  bool get useAmoled => _useAmoled;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeValue = prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeValue];
    _useDynamicColors = prefs.getBool(_dynamicKey) ?? false;
    _useAmoled = prefs.getBool(_amoledKey) ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setDynamicColors(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dynamicKey, value);
    _useDynamicColors = value;
    notifyListeners();
  }

  Future<void> setAmoled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_amoledKey, value);
    _useAmoled = value;
    notifyListeners();
  }
}