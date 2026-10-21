import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

/// Heading text style. Uses the system font (Roboto on Android) so the app
/// looks native; weights are capped at bold, as Material text does.
TextStyle disp(double size,
    {FontWeight weight = FontWeight.w700, Color? color, double? height, double? spacing}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight.value > 700 ? FontWeight.w700 : weight,
    color: color,
    height: height,
    letterSpacing: spacing,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
