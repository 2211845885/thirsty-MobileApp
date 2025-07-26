import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../services/notification_service.dart';

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
  bool _notificationsEnabled = true;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDark;
    _goalController.text = widget.goalNotifier.value.toString();
    if (widget.customSizesNotifier.value.isEmpty) {
      widget.customSizesNotifier.value = [150, 250, 350];
    }
    _loadNotificationPrefs();
  }

  Future<void> _loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notificationsEnabled') ?? true;
    final hour = prefs.getInt('notificationHour') ?? 8;
    final minute = prefs.getInt('notificationMinute') ?? 0;
    setState(() {
      _notificationsEnabled = enabled;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _saveNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('notificationsEnabled', _notificationsEnabled);

  if (_selectedTime != null) {
    await prefs.setInt('notificationHour', _selectedTime!.hour);
    await prefs.setInt('notificationMinute', _selectedTime!.minute);
  }

  await NotificationService.cancelAll();

  if (_notificationsEnabled && _selectedTime != null) {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final tzTime = tz.TZDateTime.from(scheduled, tz.local);

    try {
      await NotificationService.scheduleDaily(
        id: 1,
        title: 'Hydration Reminder',
        body: 'Time to drink water!',
        time: tzTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }
}


  Future<void> _saveGoal() async {
    final prefs = await SharedPreferences.getInstance();
    double goal = double.tryParse(_goalController.text) ?? widget.goalNotifier.value;
    goal = goal.clamp(0.5, 10.0);
    widget.goalNotifier.value = goal;
    await prefs.setDouble('goal', goal);
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
    setState(() => widget.customSizesNotifier.value = sizes);
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
          ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _saveGoal,
                  child: const Text('Save Goal', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: valueColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
            title: 'Notifications',
            cardColor: cardColor,
            textColor: textColor,
            valueColor: valueColor,
            child: Column(
              children: [
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                  title: Text("Enable Notifications", style: TextStyle(color: textColor)),
                  activeColor: valueColor,
                ),
                ListTile(
                  title: Text("Notification Time", style: TextStyle(color: textColor)),
                  subtitle: Text(
                    _selectedTime?.format(context) ?? 'No time selected',
                    style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
                  ),
                  trailing: Icon(Icons.schedule, color: valueColor),
                  onTap: _pickTime,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _saveNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: valueColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Save Notification Settings"),
                ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              "© 2025 Hydration App by Team2",
              style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.5)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}