/// ---------------------------------------------------------------------------
/// ResUniq - account_deletion_service.dart
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
import 'package:firebase_auth/firebase_auth.dart';


typedef AccountDeletionProgress = void Function(String message);

/// AccountDeletionService is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class AccountDeletionService {
  AccountDeletionService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const _operationTimeout = Duration(seconds: 25);
  static const _batchLimit = 450;

  Future<T> _withTimeout<T>(
    Future<T> operation,
    String operationName,
  ) {
    return operation.timeout(
      _operationTimeout,
      onTimeout: () => throw StateError(
        '$operationName timed out. Please check your internet connection and try again.',
      ),
    );
  }

  Future<void> deleteAccount({
    required String password,
    AccountDeletionProgress? onProgress,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No user is currently signed in.');
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw StateError('This account does not use email/password sign-in.');
    }

    onProgress?.call('Verifying your password...');

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await _withTimeout(
      user.reauthenticateWithCredential(credential),
      'Password verification',
    );

    final uid = user.uid;

    onProgress?.call('Deleting your resumes...');

    // Process a bounded number of documents at a time. This is much safer
    // than loading every resume into one large query/batch.
    while (true) {
      final snapshot = await _withTimeout(
        _db
            .collection('resumes')
            .where('ownerId', isEqualTo: uid)
            .limit(_batchLimit)
            .get(),
        'Loading resume data',
      );

      if (snapshot.docs.isEmpty) break;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await _withTimeout(
        batch.commit(),
        'Deleting resume data',
      );
    }

    onProgress?.call('Deleting your profile...');

    final profileBatch = _db.batch();
    profileBatch.delete(_db.collection('users').doc(uid));
    profileBatch.delete(_db.collection('users_personal_details').doc(uid));

    await _withTimeout(
      profileBatch.commit(),
      'Deleting profile data',
    );

    onProgress?.call('Deleting your account...');

    await _withTimeout(
      user.delete(),
      'Deleting Firebase Authentication account',
    );

    await _auth.signOut();
  }
}
