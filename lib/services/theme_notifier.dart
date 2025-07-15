import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 使用 ChangeNotifier，以便 UI 可以監聽主題變化
class ThemeNotifier extends ChangeNotifier {
  final String _key = "themeMode"; // 用於儲存到 SharedPreferences 的鍵
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    // 初始化時，預設為跟隨系統，並嘗試從本地儲存中讀取使用者先前的設定
    _themeMode = ThemeMode.system;
    _loadFromPrefs();
  }

  // 從 SharedPreferences 讀取設定
  _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeString = prefs.getString(_key);

    if (themeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    // 通知監聽者更新 UI
    notifyListeners();
  }

  // 更新主題模式，並儲存到 SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();

    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
      default:
        themeString = 'system';
        break;
    }

    await prefs.setString(_key, themeString);
    // 通知監聽者更新 UI
    notifyListeners();
  }
}