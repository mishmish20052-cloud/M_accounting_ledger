// lib/utils/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A73E8);
  static const Color secondaryColor = Color(0xFF34A853);
  static const Color errorColor = Color(0xFFEA4335);
  static const Color warningColor = Color(0xFFFBBC05);
  static const Color incomeColor = Color(0xFF34A853);
  static const Color expenseColor = Color(0xFFEA4335);
  static const Color transferColor = Color(0xFF1A73E8);

  // إزالة المعامل dynamicScheme والاعتماد على الألوان الثابتة المحددة أعلاه مباشرة
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      // ... باقي خصائص ThemeData تبقى كما هي ...
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      // ... باقي خصائص ThemeData تبقى كما هي ...
    );
  }
}
