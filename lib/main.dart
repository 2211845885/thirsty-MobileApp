import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await HydroBuddyApp.create();
  runApp(app);
}

class HydroBuddyApp extends StatefulWidget {
  final bool isDark;
  final double goal;
  final int todayIntake;
  final List<int> customSizes;

  const HydroBuddyApp._({
    Key? key,
    required this.isDark,
    required this.goal,
    required this.todayIntake,
    required this.customSizes,
  }) : super(key: key);

  static Future<Widget> create() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool('darkMode') ?? false;
    final goal = prefs.getDouble('goal') ?? 2.0;

    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    final todayIntake = prefs.getInt('intake_$todayKey') ?? 0;

    final sizes = prefs.getStringList('customSizes')?.map(int.parse).toList() ?? [200, 300, 500];

    return HydroBuddyApp._(
      isDark: isDark,
      goal: goal,
      todayIntake: todayIntake,
      customSizes: sizes,
    );
  }

  @override
  State<HydroBuddyApp> createState() => _HydroBuddyAppState();
}

class _HydroBuddyAppState extends State<HydroBuddyApp> {
  late bool _isDark;
  late final ValueNotifier<double> _goalNotifier;
  late final ValueNotifier<int> _intakeNotifier;
  late final ValueNotifier<List<int>> _customSizesNotifier;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;
    _goalNotifier = ValueNotifier(widget.goal);
    _intakeNotifier = ValueNotifier(widget.todayIntake);
    _customSizesNotifier = ValueNotifier(widget.customSizes);
  }

  void _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    setState(() => _isDark = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDark ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: HomePage(
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
        goalNotifier: _goalNotifier,
        intakeNotifier: _intakeNotifier,
        customSizesNotifier: _customSizesNotifier,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool isDark;
  final Function(bool) onToggleTheme;
  final ValueNotifier<double> goalNotifier;
  final ValueNotifier<int> intakeNotifier;
  final ValueNotifier<List<int>> customSizesNotifier;

  const HomePage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.goalNotifier,
    required this.intakeNotifier,
    required this.customSizesNotifier,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  void _handleThemeToggle() {
    final newValue = !widget.isDark;
    widget.onToggleTheme(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        isDarkTheme: widget.isDark,
        onToggleTheme: _handleThemeToggle,
        goalNotifier: widget.goalNotifier,
        intakeNotifier: widget.intakeNotifier,
        customSizesNotifier: widget.customSizesNotifier,
      ),
      StatsScreen(
        isDark: widget.isDark,
        onToggleTheme: widget.onToggleTheme,
        intakeNotifier: widget.intakeNotifier,
        goalNotifier: widget.goalNotifier,
      ),
      SettingsScreen(
        isDark: widget.isDark,
        onToggleTheme: widget.onToggleTheme,
        goalNotifier: widget.goalNotifier,
        customSizesNotifier: widget.customSizesNotifier,
        intakeNotifier: widget.intakeNotifier,
      ),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        backgroundColor: widget.isDark ? const Color(0xFF1E2A47) : Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: widget.isDark ? Colors.white70 : Colors.black54,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}