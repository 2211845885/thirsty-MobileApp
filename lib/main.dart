import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:thirsty/services/notification_service.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  await NotificationService.requestPermission();
  await NotificationService.getToken(); 
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

  Future<void> _updateIntake(int newIntake) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setInt('intake_$todayKey', newIntake);
    _intakeNotifier.value = newIntake;
  }

  Future<void> _updateGoal(double newGoal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('goal', newGoal);
    _goalNotifier.value = newGoal;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDark ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      home: HomePage(
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
        goalNotifier: _goalNotifier,
        intakeNotifier: _intakeNotifier,
        customSizesNotifier: _customSizesNotifier,
        updateIntake: _updateIntake,
        updateGoal: _updateGoal,
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

  final Future<void> Function(int) updateIntake;
  final Future<void> Function(double) updateGoal;


  const HomePage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.goalNotifier,
    required this.intakeNotifier,
    required this.customSizesNotifier,
    required this.updateIntake,
    required this.updateGoal,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  void _handleThemeToggle() {
    widget.onToggleTheme(!widget.isDark);
  }

  void _addWater(int amount) {
    final newIntake = widget.intakeNotifier.value + amount;
    widget.updateIntake(newIntake);
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
        addWater: _addWater,
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
