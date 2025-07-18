import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatefulWidget {
  final bool isDark;
  final Function(bool) onToggleTheme;
  final ValueNotifier<int> intakeNotifier;
  final ValueNotifier<double> goalNotifier;

  const StatsScreen({
    Key? key,
    required this.isDark,
    required this.onToggleTheme,
    required this.intakeNotifier,
    required this.goalNotifier,
  }) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<int> _weeklyIntake = List.filled(7, 0);
  List<int> _streakHistory = List.filled(7, 0);
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadData();

    widget.intakeNotifier.addListener(() {
      _checkGoalAndUpdateStreak();
    });
  }

  Future<void> _loadData() async {
  final prefs = await SharedPreferences.getInstance();

  // Load and parse weekly intake
  final weekListRaw = prefs.getStringList('week');
  if (weekListRaw != null && weekListRaw.length == 7) {
    _weeklyIntake = weekListRaw.map((e) => int.tryParse(e) ?? 0).toList();
  } else {
    _weeklyIntake = List.filled(7, 0);
  }

  // Load and parse streak history safely
  final streakRaw = prefs.get('streak');
  if (streakRaw is List<String> && streakRaw.length == 7) {
    try {
      _streakHistory = streakRaw.map((e) => int.tryParse(e) ?? 0).toList();
    } catch (e) {
      _streakHistory = List.filled(7, 0); // fallback
    }
  } else {
    // If streak is corrupted or legacy (e.g., int), reset it
    _streakHistory = List.filled(7, 0);
    await prefs.setStringList('streak', _streakHistory.map((e) => e.toString()).toList());
  }

  _calculateStreak();
  if (mounted) setState(() {});
}

void _calculateStreak() {
  _streak = _streakHistory.reversed.takeWhile((day) => day == 1).length;
}

  Future<void> _checkGoalAndUpdateStreak() async {
    final intake = widget.intakeNotifier.value;
    final goal = (widget.goalNotifier.value * 1000).toInt();
    final now = DateTime.now();
    final index = now.weekday % 7;

    if (intake >= goal && _streakHistory[index] != 1) {
      final prefs = await SharedPreferences.getInstance();
      _streakHistory[index] = 1;
      await prefs.setStringList(
        'streak',
        _streakHistory.map((e) => e.toString()).toList(),
      );
      _calculateStreak();
      if (mounted) setState(() {});
    }
  }

  List<String> get _weekLabels => [
        'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
      ];

  BarChartGroupData _barData(int index, int value, Color barColor) {
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          width: 18,
          borderRadius: BorderRadius.circular(6),
          color: barColor,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final mainColor = const Color(0xFF2196F3);
    final fireColor = Colors.deepOrange;
    final greyColor = Colors.grey;
    final bgColor = isDark ? const Color(0xFF0A192F) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E2A47) : const Color(0xFFF2F9FF);
    final size = MediaQuery.of(context).size;

    int bestIndex = _weeklyIntake.indexOf(_weeklyIntake.reduce((a, b) => a > b ? a : b));
    double avg = _weeklyIntake.reduce((a, b) => a + b) / _weeklyIntake.length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        title: Text(
          'Stats',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: textColor,
            ),
            onPressed: () => widget.onToggleTheme(!widget.isDark),
            tooltip: "Toggle Theme",
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _buildCard(
                      title: "Current Streak",
                      value: _streak == 0 ? "0 days 🔥" : "$_streak days 🔥",
                      valueColor: _streak == 0 ? greyColor : fireColor,
                      textColor: textColor,
                      cardColor: cardColor,
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: "Today's Intake",
                      value:
                          "${widget.intakeNotifier.value} ml / ${(widget.goalNotifier.value * 1000).toInt()} ml",
                      valueColor: mainColor,
                      textColor: textColor,
                      cardColor: cardColor,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: size.height * 0.35,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: mainColor.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, _) => Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) {
                                  int index = value.toInt();
                                  if (index >= 0 && index < _weekLabels.length) {
                                    return Text(
                                      _weekLabels[index],
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: false),
                          barGroups: List.generate(
                            7,
                            (i) => _barData(i, _weeklyIntake[i], mainColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCard(
                      title: "Best Day 💧",
                      value:
                          "${_weekLabels[bestIndex]}: ${_weeklyIntake[bestIndex]} ml",
                      valueColor: Colors.green,
                      textColor: textColor,
                      cardColor: cardColor,
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      title: "Weekly Average 📊",
                      value: "${avg.toStringAsFixed(0)} ml/day",
                      valueColor: Colors.amber,
                      textColor: textColor,
                      cardColor: cardColor,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required Color valueColor,
    required Color textColor,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: valueColor.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}