// lib/theme_notifier.dart
import 'package:flutter/material.dart';

class ThemeNotifier extends InheritedWidget {
  const ThemeNotifier({
    super.key,
    required this.themeMode,
    required this.setThemeMode,
    required super.child,
  });

  final ThemeMode themeMode;
  final void Function(ThemeMode) setThemeMode;

  static ThemeNotifier? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeNotifier>();
  }

  static ThemeNotifier of(BuildContext context) {
    final ThemeNotifier? result = maybeOf(context);
    assert(result != null, 'No ThemeNotifier found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(ThemeNotifier oldWidget) {
    return themeMode != oldWidget.themeMode;
  }
}
