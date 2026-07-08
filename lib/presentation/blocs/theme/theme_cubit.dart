import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notepad_pro/services/hive_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final HiveService _hiveService;

  ThemeCubit(this._hiveService) : super(ThemeMode.light);

  Future<void> loadFromPrefs() async {
    final isDark = _hiveService.appSettingsBox.get('isDark', defaultValue: false) as bool;
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleTheme(bool isDarkMode) async {
    await _hiveService.appSettingsBox.put('isDark', isDarkMode);
    emit(isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }
}
