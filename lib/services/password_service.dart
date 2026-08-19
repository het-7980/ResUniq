/// ---------------------------------------------------------------------------
/// ResUniq - password_service.dart
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

import 'package:firebase_auth/firebase_auth.dart';

/// PasswordService is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class PasswordService {
  PasswordService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  static const _timeout = Duration(seconds: 25);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No user is currently signed in.');
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw StateError(
        'This account does not use email/password sign-in.',
      );
    }

    // Firebase requires a recent sign-in for sensitive account changes.
    // Re-authenticate with the current password before updating it.
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await user
        .reauthenticateWithCredential(credential)
        .timeout(_timeout);

    await user.updatePassword(newPassword).timeout(_timeout);
  }
}
