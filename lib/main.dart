import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/shared/providers/preferences_provider.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize local database
  await AppDatabase.instance;
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Pre-warm the blur shader so the first animation doesn't jank.
  // This forces the GPU to compile the BackdropFilter pipeline ahead of time.
  _warmUpBlurShader();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SpendlyApp(),
    ),
  );
}

/// Triggers a tiny off-screen blur to pre-compile the shader pipeline.
void _warmUpBlurShader() {
  try {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.saveLayer(const Rect.fromLTWH(0, 0, 1, 1), Paint());
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1, 1),
      Paint()..imageFilter = ImageFilter.blur(sigmaX: 4, sigmaY: 4),
    );
    canvas.restore();
    final picture = recorder.endRecording();
    picture.toImage(1, 1).then((image) => image.dispose());
    picture.dispose();
  } catch (_) {
    // Shader warmup is best-effort; silently ignore failures.
  }
}
