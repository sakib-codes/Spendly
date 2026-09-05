import 'package:flutter/animation.dart';

class AnimationTokens {
  // Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);

  // Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve springCurve = Curves.easeOutBack;
}
