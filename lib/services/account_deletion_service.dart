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
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';


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
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

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

  /// Reauthenticates the currently signed-in user with Google.
  ///
  /// A Google account has no application password, so deletion is confirmed
  /// by obtaining a fresh Google credential and reauthenticating Firebase.
  Future<void> _reauthenticateWithGoogle(User user) async {
    if (kIsWeb) {
      // FlutterFire's federated provider reauthentication method is not
      // implemented on the web. For web, Firebase requires a popup (or
      // redirect) flow to obtain a fresh Google credential.
      await _withTimeout(
        user.reauthenticateWithPopup(GoogleAuthProvider()),
        'Google verification',
      );
      return;
    }

    if (!_googleInitialized) {
      await _withTimeout(
        _googleSignIn.initialize(),
        'Google initialization',
      );
      _googleInitialized = true;
    }

    if (!_googleSignIn.supportsAuthenticate()) {
      throw FirebaseAuthException(
        code: 'google-sign-in-not-supported',
        message: 'Google reauthentication is not supported on this platform.',
      );
    }

    late final GoogleSignInAccount googleUser;
    try {
      googleUser = await _withTimeout(
        _googleSignIn.authenticate(),
        'Google verification',
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw FirebaseAuthException(
          code: 'canceled',
          message: 'Google verification was cancelled.',
        );
      }
      throw FirebaseAuthException(
        code: 'google-reauthentication-failed',
        message: e.description ?? 'Unable to verify your Google account.',
      );
    }

    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google verification did not return an ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    await _withTimeout(
      user.reauthenticateWithCredential(credential),
      'Google verification',
    );
  }

  Future<void> deleteAccount({
    String? password,
    AccountDeletionProgress? onProgress,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No user is currently signed in.');
    }

    final providers = user.providerData.map((info) => info.providerId).toSet();
    final isGoogleUser = providers.contains('google.com');
    final isPasswordUser = providers.contains('password');

    // Firebase requires recent authentication before deleting an account.
    // Email/password users are verified with their password, while Google
    // users are verified with a fresh Google authentication instead.
    if (isPasswordUser) {
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw StateError('This account does not have a valid email address.');
      }
      if (password == null || password.isEmpty) {
        throw StateError('A password is required for this account.');
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
    } else if (isGoogleUser) {
      onProgress?.call('Verifying your Google account...');
      await _reauthenticateWithGoogle(user);
    } else {
      throw StateError(
        'This account uses an unsupported sign-in provider. '
        'Please sign in again before deleting it.',
      );
    }

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

    // user.delete() invalidates the current Firebase Authentication session.
    // CheckAuth listens to authStateChanges() and will automatically show the
    // sign-in screen, so an additional signOut() is unnecessary.
  }
}
