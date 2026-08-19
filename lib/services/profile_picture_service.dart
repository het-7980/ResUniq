/// ---------------------------------------------------------------------------
/// ResUniq - profile_picture_service.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Application services and repositories. These classes contain Firebase, Gemini, PDF, authentication, profile, and data-access logic so screens can stay focused on UI.
///
/// BEGINNER GUIDE:
/// - UI screens/widgets should mainly display information and collect input.
/// - Providers hold/change state that the UI listens to.
/// - Services/repositories perform Firebase, API, PDF, or other data work.
/// - Models describe the data passed between these layers.
///
/// TIP:
/// Read this file together with the classes it imports. The imported classes
/// usually explain where data comes from and where actions are performed.
/// ---------------------------------------------------------------------------
library;

import 'dart:convert';
import 'dart:typed_data';

/// Handles profile images without Firebase Storage.
///
/// The compressed JPEG is stored as a data URL in
/// users_personal_details/{uid}.profileImageUrl.
/// Keeping the image small is important because Firestore documents have a
/// 1 MiB maximum size.
class ProfilePictureService {
  static const int maxBytes = 300 * 1024;

  static String encode(Uint8List bytes) {
    if (bytes.length > maxBytes) {
      throw StateError(
        'Profile photo is too large. Please choose a smaller photo.',
      );
    }
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  static Uint8List? decode(String value) {
    if (value.isEmpty) return null;

    try {
      const marker = 'base64,';
      final index = value.indexOf(marker);
      if (index >= 0) {
        return base64Decode(value.substring(index + marker.length));
      }
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }
}
