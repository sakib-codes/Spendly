import 'package:flutter/foundation.dart';

/// Global state to track if a heavy page transition is currently happening.
/// Used to temporarily disable expensive effects like BackdropFilter during animations.
final ValueNotifier<bool> globalIsAnimating = ValueNotifier<bool>(false);
