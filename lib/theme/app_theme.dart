import 'package:flutter/material.dart';

class AppTheme {
  static const bg = Colors.white;
  static const card = Colors.cyan;
  static const accent = Colors.yellow;
  static final light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.light(primary: card),
    useMaterial3: true,
  );
}