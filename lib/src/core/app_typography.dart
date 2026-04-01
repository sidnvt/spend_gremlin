import 'package:flutter/material.dart';

class AppTypography {
  static const String serif = 'serif';
  static const String mono = 'monospace';

  static TextStyle monoLabel({
    double size = 10,
    Color? color,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = 0.6,
  }) {
    return TextStyle(
      fontFamily: mono,
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle serifAmount({
    double size = 14,
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: serif,
      fontSize: size,
      color: color,
      fontWeight: weight,
    );
  }
}

