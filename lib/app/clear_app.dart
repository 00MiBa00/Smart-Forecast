import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../features/library/screens/library_home_screen.dart';
import '../features/review/screens/review_dashboard_screen.dart';
import '../features/create/screens/create_home_screen.dart';
import '../features/settings/screens/settings_screen.dart';

class DocTrainerApp extends StatefulWidget {
  const DocTrainerApp({super.key});

  @override
  State<DocTrainerApp> createState() => _DocTrainerAppState();
}

class _DocTrainerAppState extends State<DocTrainerApp> {
  static const String _themeKey = 'theme_brightness';
  Brightness _brightness = Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? true;
    setState(() {
      _brightness = isDark ? Brightness.dark : Brightness.light;
    });
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final newBrightness = _brightness == Brightness.dark ? Brightness.light : Brightness.dark;
    await prefs.setBool(_themeKey, newBrightness == Brightness.dark);
    setState(() {
      _brightness = newBrightness;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      key: ValueKey(_brightness),
      title: 'DocTrainer',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: _brightness,
        primaryColor: AppTheme.accentBlue,
        scaffoldBackgroundColor: _brightness == Brightness.dark 
            ? AppTheme.backgroundColor 
            : CupertinoColors.systemGroupedBackground,
        barBackgroundColor: _brightness == Brightness.dark
            ? AppTheme.surfaceColor
            : CupertinoColors.systemBackground,
        textTheme: CupertinoTextThemeData(
          primaryColor: _brightness == Brightness.dark
              ? AppTheme.primaryText
              : CupertinoColors.label,
          textStyle: AppTheme.body,
        ),
      ),
      home: MainTabScreen(
        onThemeToggle: toggleTheme,
        brightness: _brightness,
      ),
    );
  }
}

class MainTabScreen extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final Brightness brightness;

  const MainTabScreen({
    super.key,
    required this.onThemeToggle,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: isDark ? AppTheme.surfaceColor : CupertinoColors.systemBackground,
        activeColor: AppTheme.accentBlue,
        inactiveColor: isDark ? AppTheme.secondaryText : CupertinoColors.inactiveGray,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.book),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.checkmark_circle),
            label: 'Review',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.add_circled),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const LibraryHomeScreen();
          case 1:
            return const ReviewDashboardScreen();
          case 2:
            return const CreateHomeScreen();
          case 3:
            return SettingsScreen(
              onThemeToggle: onThemeToggle,
              brightness: brightness,
            );
          default:
            return const LibraryHomeScreen();
        }
      },
    );
  }
}
  