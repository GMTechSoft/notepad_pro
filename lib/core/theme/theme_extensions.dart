import 'package:flutter/material.dart';

extension ThemeContext on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get primaryColor => colorScheme.primary;
  Color get cardBg => colorScheme.surface;
  Color get primaryText => colorScheme.onSurface;
  Color get subText => colorScheme.onSurfaceVariant;
  Color get border => colorScheme.outline;
  Color get highlightBg => colorScheme.primaryContainer;
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
}
