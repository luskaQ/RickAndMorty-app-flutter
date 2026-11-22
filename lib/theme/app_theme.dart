import 'package:flutter/material.dart';

class AppTheme {
  static const bg = Colors.cyan;
  static const card = Colors.white;
  static const accent = Colors.yellow;
  static final light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.light(primary: card, secondary: accent),
    cardTheme: const CardThemeData(color: card),
    appBarTheme: const AppBarTheme(backgroundColor: accent),
    useMaterial3: true,
  );
}