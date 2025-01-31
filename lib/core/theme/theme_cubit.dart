import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState extends Equatable {
  final bool isDark;
  final Color primaryColor;

  const ThemeState({
    this.isDark = false,
    this.primaryColor = Colors.pink,
  });

  ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeState copyWith({
    bool? isDark,
    Color? primaryColor,
  }) {
    return ThemeState(
      isDark: isDark ?? this.isDark,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }

  @override
  List<Object?> get props => [isDark, primaryColor];
}

class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeKey = 'is_dark_mode';
  static const String _colorKey = 'primary_color';
  final SharedPreferences _prefs;

  ThemeCubit({required SharedPreferences prefs})
      : _prefs = prefs,
        super(ThemeState(
          isDark: prefs.getBool('is_dark_mode') ?? false,
          primaryColor:
              Color(prefs.getInt('primary_color') ?? Colors.pink.value),
        ));

  void toggleTheme() {
    final newIsDark = !state.isDark;
    _prefs.setBool(_themeKey, newIsDark);
    emit(state.copyWith(isDark: newIsDark));
  }

  void updatePrimaryColor(Color color) {
    _prefs.setInt(_colorKey, color.value);
    emit(state.copyWith(primaryColor: color));
  }
}
