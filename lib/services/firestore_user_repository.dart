/// ---------------------------------------------------------------------------
/// ResUniq - firestore_user_repository.dart
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

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import 'user_repository.dart';

/// Reads and updates the profile at users/{Firebase Authentication UID}.
///
/// This is the single user-profile location used by ResUniq for both normal
/// users and administrators. Admins created by admin_tools/create_admin.js
/// are written to this exact UID-based document.
class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('users').doc(uid);

  @override
  Stream<UserProfile?> watchProfile() async* {
    await for (final snapshot in _doc.snapshots()) {
      if (snapshot.exists && snapshot.data() != null) {
        yield UserProfile.fromMap(uid, snapshot.data()!);
      } else {
        yield null;
      }
    }
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    // Always write to the authenticated user's UID document. This prevents
    // old email-based profile documents from being used accidentally.
    await _doc.set(
      profile.toMap(),
      SetOptions(merge: true),
    );
  }
}
