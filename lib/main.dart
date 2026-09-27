import 'package:flutter/material.dart';
import 'package:trabalho01_flutter/view/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.delayed(const Duration(seconds: 2));
  runApp(
    MaterialApp(
      home: HomePage(),
    ),
  );
}