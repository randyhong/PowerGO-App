import 'package:flutter/material.dart';
import 'package:powergo/screens/main_screen.dart';
import 'package:powergo/services/settings_service.dart';

void main() {
  runApp(const PowerGoApp());
}

class PowerGoApp extends StatefulWidget {
  const PowerGoApp({Key? key}) : super(key: key);

  @override
  State<PowerGoApp> createState() => _PowerGoAppState();

  // 静态方法用于从任何地方更新主题
  static void updateTheme(BuildContext context) {
    final state = context.findAncestorStateOfType<_PowerGoAppState>();
    state?._loadTheme();
  }
}

class _PowerGoAppState extends State<PowerGoApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final appThemeMode = await SettingsService.getThemeMode();
    final flutterThemeMode = SettingsService.appThemeModeToFlutterThemeMode(appThemeMode);
    if (mounted) {
      setState(() {
        _themeMode = flutterThemeMode;
      });
    }
  }

  ThemeData get _lightTheme => ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue.shade700,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          elevation: 8,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      );

  ThemeData get _darkTheme => ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue.shade300,
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 8,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PowerGo',
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _themeMode,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}