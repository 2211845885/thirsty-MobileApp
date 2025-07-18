import 'package:flutter/material.dart';

class ThemeToggleIcon extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onToggle;

  const ThemeToggleIcon({
    Key? key,
    required this.isDark,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      tooltip: "Toggle Theme",
      onPressed: () => onToggle(!isDark),
    );
  }
}