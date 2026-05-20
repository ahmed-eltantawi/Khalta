import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _boxName = 'app_prefs';
  static const _key = 'theme_mode';

  ThemeCubit() : super(_loadFromBox());

  static ThemeMode _loadFromBox() {
    final box = Hive.box(_boxName);
    final value = box.get(_key, defaultValue: 'dark');
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  void toggleTheme() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _save(next);
    emit(next);
  }

  void setTheme(ThemeMode mode) {
    _save(mode);
    emit(mode);
  }

  void _save(ThemeMode mode) {
    final box = Hive.box(_boxName);
    box.put(_key, mode.name);
  }

  bool get isDark => state == ThemeMode.dark;
}
