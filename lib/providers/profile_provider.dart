import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileProvider with ChangeNotifier {
  String? _profileImagePath;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Returns the current profile image path, or null if not set or file missing.
  String? get profileImagePath => _profileImagePath;

  /// Initializes the provider by loading the persisted image path from secure storage
  /// and verifying that the file still exists on disk.
  ///
  /// Should be called once during app startup (e.g., in main.dart).
  Future<void> init() async {
    final savedPath = await _secureStorage.read(key: 'profile_image_path');

    // If no path was saved, ensure state is clean
    if (savedPath == null) {
      if (_profileImagePath != null) {
        _profileImagePath = null;
        notifyListeners();
      }
      return;
    }

    // Verify the file actually exists to avoid broken image states
    final file = File(savedPath);
    if (await file.exists()) {
      // Only update if value changed to prevent unnecessary rebuilds
      if (_profileImagePath != savedPath) {
        _profileImagePath = savedPath;
        notifyListeners();
      }
    } else {
      // File is missing — treat as no image and clean up storage
      if (kDebugMode) {
        debugPrint('⚠️ Profile image file missing: $savedPath. Clearing reference.');
      }
      await _secureStorage.delete(key: 'profile_image_path');
      if (_profileImagePath != null) {
        _profileImagePath = null;
        notifyListeners();
      }
    }
  }

  /// Updates the profile image path and persists it securely.
  /// Pass `null` to clear the image.
  void updateProfileImagePath(String? path) {
    if (_profileImagePath == path) return; // Avoid redundant updates

    _profileImagePath = path;

    // Persist or clear in secure storage
    if (path != null) {
      _secureStorage.write(key: 'profile_image_path', value: path);
    } else {
      _secureStorage.delete(key: 'profile_image_path');
    }

    notifyListeners();
  }
}