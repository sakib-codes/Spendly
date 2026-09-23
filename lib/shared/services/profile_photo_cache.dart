import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Manages a locally cached copy of the user's profile picture.
///
/// The image is stored on disk at `<appDir>/profile_photo.jpg`.
/// It is only downloaded once (on login or Google sign-in).
/// When the user uploads a new photo, the picked file is copied
/// directly into the cache — zero network round-trips.
class ProfilePhotoCache {
  static final ProfilePhotoCache instance = ProfilePhotoCache._();
  ProfilePhotoCache._();

  /// In-memory notifier so widgets rebuild instantly when the photo changes.
  final ValueNotifier<File?> photoNotifier = ValueNotifier<File?>(null);

  File? _cachedFile;

  /// Returns the cache file path (may or may not exist yet).
  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/profile_photo.jpg');
  }

  /// Called once at login / app start.
  /// If a local copy exists, it is used immediately (no network).
  /// Otherwise the photo is downloaded from [url] and saved to disk.
  Future<void> load(String? url) async {
    final file = await _cacheFile();

    // Already cached on disk → use it instantly.
    if (file.existsSync()) {
      _cachedFile = file;
      photoNotifier.value = file;
      return;
    }

    // No local copy → download from Firebase Storage URL.
    if (url != null && url.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          _cachedFile = file;
          photoNotifier.value = file;
        }
      } catch (_) {
        // Network error — show placeholder, no crash.
      }
    }
  }

  /// Called when the user picks a new photo from gallery.
  /// Copies the picked file directly into the cache — instant, no download.
  Future<void> updateFromFile(File pickedFile) async {
    final file = await _cacheFile();
    await pickedFile.copy(file.path);
    _cachedFile = file;
    // Trigger rebuild by creating a new File instance (same path, new object)
    photoNotifier.value = File(file.path);
  }

  /// Called on logout — deletes the cached file so the next
  /// user gets a fresh download.
  Future<void> clear() async {
    final file = await _cacheFile();
    if (file.existsSync()) {
      await file.delete();
    }
    _cachedFile = null;
    photoNotifier.value = null;
  }

  /// Synchronous getter for widgets that just need the current file.
  File? get currentFile => _cachedFile;
}
