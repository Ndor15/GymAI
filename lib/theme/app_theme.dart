import 'package:flutter/material.dart';

class AppTheme {
  static const Color yellow = Color(0xFFF5C32E);
  static const Color orange = Color(0xFFFFA500);
  static const Color dark = Color(0xFF0D0D0D);
  static const Color background = Color(0xFF050505);

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: dark,
    primaryColor: yellow,
    useMaterial3: true,
    fontFamily: "Inter",
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white, fontSize: 16),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 20),
    ),
  );
}
