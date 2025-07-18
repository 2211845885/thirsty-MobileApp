import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDark;
  final Function(bool) onToggleTheme;
  final ValueNotifier<double> goalNotifier;
  final ValueNotifier<List<int>> customSizesNotifier;
  final ValueNotifier<int> intakeNotifier;

  const SettingsScreen({
    Key? key,
    required this.isDark,
    required this.onToggleTheme,
    required this.goalNotifier,
    required this.customSizesNotifier,
    required this.intakeNotifier,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _customSizeController = TextEditingController();
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDark;
    _goalController.text = widget.goalNotifier.value.toString();
    if (widget.customSizesNotifier.value.isEmpty) {
      widget.customSizesNotifier.value = [150, 250, 350];
    }
  }

  Future<void> _saveGoal() async {
  final prefs = await SharedPreferences.getInstance();
  
  double goal = double.tryParse(_goalController.text) ?? widget.goalNotifier.value;
  goal = goal.clamp(0.5, 10.0); // safety range
  widget.goalNotifier.value = goal;

  await prefs.setDouble('goal', goal);

  final intake = widget.intakeNotifier.value.toDouble();
  final today = DateTime.now().toIso8601String().split('T').first;
  final lastStreakDate = prefs.getString('lastStreakDate');

  dynamic storedStreak = prefs.get('streak');
  int streak;
  if (storedStreak is int) {
    streak = storedStreak;
  } else {
    // Clear bad data and start fresh
    await prefs.remove('streak');
    streak = 0;
  }

  if (intake >= goal && lastStreakDate != today) {
    streak++;
    await prefs.setInt('streak', streak);
    await prefs.setString('lastStreakDate', today);
  }
}

  Future<void> _addCustomSize() async {
    final prefs = await SharedPreferences.getInstance();
    int? newSize = int.tryParse(_customSizeController.text);
    if (newSize == null || newSize <= 0) return;

    final sizes = [...widget.customSizesNotifier.value, newSize];
    setState(() {
      widget.customSizesNotifier.value = sizes;
      _customSizeController.clear();
    });
    await prefs.setStringList('customSizes', sizes.map((e) => e.toString()).toList());
  }

  Future<void> _removeCustomSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    final sizes = widget.customSizesNotifier.value.where((e) => e != size).toList();
    setState(() {
      widget.customSizesNotifier.value = sizes;
    });
    await prefs.setStringList('customSizes', sizes.map((e) => e.toString()).toList());
  }

  Future<void> _resetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    widget.goalNotifier.value = 2;
    widget.customSizesNotifier.value = [150, 250, 350];
    widget.intakeNotifier.value = 0;

    _goalController.text = "2000";

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All data has been reset.")),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    required Color cardColor,
    required Color textColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: valueColor.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
          )
        ],
      ),
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? const Color(0xFF0A192F) : Colors.white;
    final cardColor = _isDarkMode ? const Color(0xFF1E2A47) : const Color(0xFFE3F2FD);
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    final valueColor = _isDarkMode ? Colors.lightBlueAccent : Colors.blue;
    final errorColor = Colors.redAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text('Settings', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () async {
              setState(() => _isDarkMode = !_isDarkMode);
              widget.onToggleTheme(_isDarkMode);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isDarkMode', _isDarkMode);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: 'Daily Goal (ml)',
            cardColor: cardColor,
            textColor: textColor,
            valueColor: valueColor,
            child: Column(
              children: [
                TextField(
                  controller: _goalController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: "e.g. 2500",
                    filled: true,
                    fillColor: _isDarkMode ? cardColor : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveGoal,
                    child: const Text('Save Goal', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: valueColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildCard(
            title: 'Custom Cup Sizes (ml)',
            cardColor: cardColor,
            textColor: textColor,
            valueColor: valueColor,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customSizeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "e.g. 250",
                          filled: true,
                          fillColor: _isDarkMode ? cardColor : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        style: TextStyle(color: textColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addCustomSize,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: valueColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: widget.customSizesNotifier.value.map((size) {
                    return Chip(
                      label: Text("$size ml", style: const TextStyle(color: Colors.white)),
                      backgroundColor: valueColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      deleteIcon: const Icon(Icons.close, color: Colors.white),
                      onDeleted: () => _removeCustomSize(size),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          _buildCard(
            title: '💧 Benefits of Drinking Water',
            cardColor: cardColor,
            textColor: textColor,
            valueColor: valueColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...[
                  "⚡ Boosts energy & relieves fatigue",
                  "🚰 Flushes out toxins from the body",
                  "🌟 Improves skin complexion",
                  "🌡️ Helps maintain body temperature",
                  "🍽️ Aids in digestion and weight loss",
                ].map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(b, style: TextStyle(color: textColor)),
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text("Reset All Data"),
            onPressed: _resetData,
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              "© 2025 Hydration App by Team2",
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}