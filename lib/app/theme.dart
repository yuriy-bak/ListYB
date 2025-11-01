import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() => FlexThemeData.light(
        scheme: FlexScheme.brandBlue,
        useMaterial3: true,
      );

  static ThemeData dark() => FlexThemeData.dark(
        scheme: FlexScheme.brandBlue,
        useMaterial3: true,
      );
}
