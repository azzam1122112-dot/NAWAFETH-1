import 'package:flutter/material.dart';

class MyThemeController extends InheritedWidget {
  final void Function(ThemeMode) changeTheme;
  final void Function(Locale) changeLanguage;
  final ThemeMode themeMode;
  final Locale locale;

  const MyThemeController({
    super.key,
    required this.changeTheme,
    required this.themeMode,
    required this.changeLanguage,
    required this.locale,
    required super.child,
  });

  static MyThemeController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MyThemeController>();

  @override
  bool updateShouldNotify(MyThemeController oldWidget) =>
      oldWidget.themeMode != themeMode || oldWidget.locale != locale;
}
