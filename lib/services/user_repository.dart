/// ---------------------------------------------------------------------------
/// ResUniq - user_repository.dart
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

import '../models/user_profile.dart';

/// Reads the signed-in user's profile from `users/{uid}`
/// (name, email, role) -- the collection your signup flow already writes to.
abstract class UserRepository {
  Stream<UserProfile?> watchProfile();
  Future<void> updateProfile(UserProfile profile);
}
