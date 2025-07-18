import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watertracker11/services/notification_service.dart';

import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const HydroBuddyApp());
}

class HydroBuddyApp extends StatefulWidget {
  const HydroBuddyApp({super.key});

  @override
  State<HydroBuddyApp> createState() => _HydroBuddyAppState();
}

class _HydroBuddyAppState extends State<HydroBuddyApp> {
  bool _isDark = false;

  final ValueNotifier<double> _goalNotifier = ValueNotifier(4.0);
  final ValueNotifier<int> _intakeNotifier = ValueNotifier(0);
  final ValueNotifier<List<int>> _customSizesNotifier = ValueNotifier([200, 300, 500]);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    _isDark = prefs.getBool('darkMode') ?? false;
    _goalNotifier.value = (prefs.getInt('dailyGoal') ?? 4000) / 1000;
    _intakeNotifier.value = prefs.getInt('intake') ?? 0;

    final sizes = prefs.getStringList('customSizes')?.map(int.parse).toList();
    if (sizes != null) _customSizesNotifier.value = sizes;

    final reminderEnabled = prefs.getBool('reminderEnabled') ?? false;
    if (reminderEnabled) {
      final reminderTimes = _loadReminderTimes(prefs);
      if (reminderTimes.isNotEmpty) {
        await NotificationService.scheduleMultipleReminders(
          reminderTimes,
          'Time to drink some water and stay hydrated! 💧',
        );
      }
    } else {
      await NotificationService.cancelAllReminders();
    }

    setState(() {});
  }

  List<TimeOfDay> _loadReminderTimes(SharedPreferences prefs) {
    final timeStrings = prefs.getStringList('reminderTimes') ?? ['08:00'];
    return timeStrings.map((str) {
      final parts = str.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();
  }

  void _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDark = value);
    await prefs.setBool('darkMode', value);
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

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        isDarkTheme: widget.isDark,
        onToggleTheme: () => widget.onToggleTheme(!widget.isDark),
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