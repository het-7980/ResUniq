/// ---------------------------------------------------------------------------
/// ResUniq - admin_repository.dart
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

import '../models/resume_document.dart';
import '../models/user_profile.dart';

/// Storage-agnostic contract for the admin panel: reading every user
/// and every resume (not just the signed-in user's own), and the
/// moderation actions an admin can take.
abstract class AdminRepository {
  Stream<List<UserProfile>> watchAllUsers();
  Stream<List<ResumeDocument>> watchAllResumes();

  Future<void> setUserRole(String uid, String role);
  Future<void> setUserDisabled(String uid, bool disabled);
  Future<void> deleteResume(String id);
}
