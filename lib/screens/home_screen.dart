// Keep all imports the same
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/droplet_painter.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkTheme;
  final VoidCallback onToggleTheme;
  final ValueNotifier<double> goalNotifier;
  final ValueNotifier<int> intakeNotifier;
  final ValueNotifier<List<int>> customSizesNotifier;

  const HomeScreen({
    Key? key,
    required this.isDarkTheme,
    required this.onToggleTheme,
    required this.goalNotifier,
    required this.intakeNotifier,
    required this.customSizesNotifier,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  double _liters = 0.0;
  String _lastDate = "";
  late AnimationController _controller;
  double _wavePhase = 0.0;

  final List<String> _messages = [
    "You're doing amazing! Keep it up! 🌟",
    "Crushing your hydration goal! 💧",
    "Keep sipping, superstar! ✨",
    "Hydration hero in action! 🚀",
    "Every drop counts! 🧊",
    "Great work! Stay refreshed! 🥤",
    "Your body loves this! 💙",
    "Cheers to good health! 🥂",
    "You're fueling your day right! 🔥",
    "Sip, smile, repeat! 😄",
    "Stay strong, stay hydrated! 💪",
    "You're almost at your goal! 🏁",
    "Water = Energy. You're glowing! ✨",
    "This drop is for your skin! 💧🧴",
    "Hustle hydrated, always! 🏃‍♂️💦",
    "Water warriors don't quit! 🛡️💦",
  ];

  final Random _random = Random();
  String _currentMessage = "";

  late final VoidCallback _customSizeListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(() => setState(() => _wavePhase += 0.03))
      ..repeat();

    _customSizeListener = () => setState(() {});
    widget.customSizesNotifier.addListener(_customSizeListener);

    _randomizeMessage();
    _loadData();
  }

  void _randomizeMessage() {
    setState(() {
      _currentMessage = _messages[_random.nextInt(_messages.length)];
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.customSizesNotifier.removeListener(_customSizeListener);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNewDay();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkNewDay();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    _liters = prefs.getDouble('intake') ?? 0.0;
    _lastDate = prefs.getString('lastDate') ?? _formattedDate();

    if (_lastDate != _formattedDate()) {
      await _resetForNewDay(prefs);
    } else {
      widget.intakeNotifier.value = (_liters * 1000).toInt();
    }

    final storedSizes = prefs.getStringList('customSizes')?.map(int.parse).toList();
    if (storedSizes != null) {
      widget.customSizesNotifier.value = storedSizes;
    }
  }

  Future<void> _checkNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    String currentDate = _formattedDate();

    if (_lastDate != currentDate) {
      await _resetForNewDay(prefs);
      _lastDate = currentDate;
    }
  }

  Future<void> _resetForNewDay(SharedPreferences prefs) async {
    List<String> week = prefs.getStringList('week') ?? List.filled(7, '0');
    int today = DateTime.now().weekday % 7;
    week[today] = '0';
    await prefs.setStringList('week', week);

    prefs.setDouble('intake', 0.0);
    prefs.setString('lastDate', _formattedDate());

    _liters = 0.0;
    widget.intakeNotifier.value = -1;
    widget.intakeNotifier.value = 0;
  }

  Future<void> _addWater(double amount) async {
    setState(() {
      _liters += amount;
    });
    _randomizeMessage();

    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('intake', _liters);
    widget.intakeNotifier.value = (_liters * 1000).toInt();

    List<String> week = prefs.getStringList('week') ?? List.filled(7, '0');
    int today = DateTime.now().weekday % 7;
    week[today] = ((_liters * 1000).toInt()).toString();
    await prefs.setStringList('week', week);

    double goal = widget.goalNotifier.value;
    if (_liters >= goal) {
      String todayKey = _formattedDate();
      Map<String, String> streakMap = {};

      final streakString = prefs.getString('hydrationStreakMap');
      if (streakString != null && streakString.isNotEmpty) {
        for (var pair in streakString.split(';')) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            streakMap[parts[0]] = parts[1];
          }
        }
      }

      streakMap[todayKey] = '1';
      final newStreakString = streakMap.entries.map((e) => '${e.key}:${e.value}').join(';');
      await prefs.setString('hydrationStreakMap', newStreakString);
    }
  }

  String _formattedDate() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkTheme;
    final screenSize = MediaQuery.of(context).size;

    final Color mainColor = const Color(0xFF2196F3);
    final Color bgColor = isDark ? const Color(0xFF0A192F) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return ValueListenableBuilder<double>(
      valueListenable: widget.goalNotifier,
      builder: (context, goal, _) {
        double percent = (_liters / goal).clamp(0.0, 1.0);
        int ml = (_liters * 1000).toInt();

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            title: Text(
              'Thirsty',
              style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: textColor,
                ),
                onPressed: widget.onToggleTheme,
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double dropletSize = constraints.maxWidth * 0.4;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _randomizeMessage,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            _currentMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: mainColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: CustomPaint(
                          size: Size(dropletSize, dropletSize * 1.5),
                          painter: DropletPainter(
                            fillPercent: percent,
                            wavePhase: _wavePhase,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(child: _buildInfoColumn("Today", "$ml ml", mainColor, isDark)),
                          Expanded(child: _buildInfoColumn("Goal", "${(goal * 1000).toInt()} ml", mainColor, isDark)),
                          Expanded(child: _buildInfoColumn("Progress", "${(percent * 100).toInt()}%", mainColor, isDark)),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: widget.customSizesNotifier.value
                            .map((ml) => _buildWaterButton(ml / 1000, mainColor, screenSize))
                            .toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoColumn(String title, String value, Color mainColor, bool isDark) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mainColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.black),
        ),
      ],
    );
  }

  Widget _buildWaterButton(double amount, Color color, Size screenSize) {
    final int ml = (amount * 1000).toInt();
    final double size = screenSize.width / 4.2;

    return GestureDetector(
      onTap: () => _addWater(amount),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: widget.isDarkTheme ? const Color(0xFF1E2A47) : color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.opacity, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              "$ml ml",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}