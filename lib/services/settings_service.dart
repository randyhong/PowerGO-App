import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'debug_service.dart';

enum AppThemeMode {
  system, // 跟随系统
  light,  // 浅色模式
  dark,   // 深色模式
}

class SettingsService {
  static const String _keyAutoRefresh = 'auto_refresh';
  static const String _keyRefreshInterval = 'refresh_interval';
  static const String _keyThemeMode = 'theme_mode';

  // 获取自动刷新设置
  static Future<bool> getAutoRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoRefresh) ?? true; // 默认开启
  }

  // 设置自动刷新
  static Future<void> setAutoRefresh(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoRefresh, value);
  }

  // 获取刷新间隔
  static Future<int> getRefreshInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyRefreshInterval) ?? 3; // 默认3秒
  }

  // 设置刷新间隔
  static Future<void> setRefreshInterval(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRefreshInterval, seconds);
  }

  // 获取主题模式设置
  static Future<AppThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyThemeMode);
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system; // 默认跟随系统
    }
  }

  // 设置主题模式
  static Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String value;
    switch (mode) {
      case AppThemeMode.light:
        value = 'light';
        break;
      case AppThemeMode.dark:
        value = 'dark';
        break;
      case AppThemeMode.system:
        value = 'system';
        break;
    }
    await prefs.setString(_keyThemeMode, value);
  }

  // 兼容旧版本的深色模式方法
  static Future<bool> getDarkMode() async {
    final themeMode = await getThemeMode();
    return themeMode == AppThemeMode.dark;
  }

  // 兼容旧版本的深色模式方法
  static Future<void> setDarkMode(bool value) async {
    await setThemeMode(value ? AppThemeMode.dark : AppThemeMode.light);
  }

  // 将AppThemeMode转换为Flutter的ThemeMode
  static ThemeMode appThemeModeToFlutterThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}