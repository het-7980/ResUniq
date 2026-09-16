/// ---------------------------------------------------------------------------
/// ResUniq - google_auth_service.dart
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

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles Google authentication for Firebase Authentication.
///
/// On Android/iOS/macOS this uses the native Google Sign-In flow and then
/// exchanges the Google ID token for a Firebase credential. On web it uses
/// Firebase's Google popup flow.
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    // google_sign_in 7.x requires initialize() to be called exactly once
    // before authenticate(). On Android, the plugin reads the OAuth client
    // configuration from google-services.json.
    await _googleSignIn.initialize();
    _initialized = true;
  }

  Future<UserCredential> signIn() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return _auth.signInWithPopup(provider);
    }

    await initialize();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw FirebaseAuthException(
        code: 'google-sign-in-not-supported',
        message: 'Google sign-in is not supported on this platform.',
      );
    }

    try {
      // Firebase logout and Google logout are separate sessions. Clear the
      // previously selected Google account before every interactive login so
      // the account chooser is shown again.
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.authenticate().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw FirebaseAuthException(
          code: 'google-sign-in-timeout',
          message: 'Google sign-in timed out. Please try again.',
        ),
      );

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message:
              'Google did not return an ID token. Check the Android Firebase '
              'configuration, SHA-1/SHA-256 fingerprints, and OAuth client.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      try {
        return await _auth.signInWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        // Keep Firebase's original error code/message so the UI can show
        // something useful instead of hiding the real authentication error.
        rethrow;
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw FirebaseAuthException(
          code: 'canceled',
          message: 'Google sign-in was cancelled.',
        );
      }

      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw FirebaseAuthException(
          code: 'google-client-configuration-error',
          message:
              'Google Sign-In is not configured correctly for this Android '
              'app. Verify google-services.json, the Android package name, '
              'SHA-1/SHA-256 fingerprints, and the Web OAuth client.',
        );
      }

      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: e.description ?? 'Unable to sign in with Google.',
      );
    }
  }

  Future<void> ensureUserProfile(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final personalRef =
        _firestore.collection('users_personal_details').doc(user.uid);

    final snapshot = await userRef.get();
    final displayName = (user.displayName ?? '').trim();
    final email = (user.email ?? '').trim();

    if (!snapshot.exists || snapshot.data() == null) {
      final batch = _firestore.batch();

      batch.set(userRef, {
        'name': displayName,
        'email': email,
        'role': 'user',
        'disabled': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(personalRef, {
        'name': displayName,
        'email': email,
        'phone': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return;
    }

    final existing = snapshot.data()!;
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if ((existing['email'] as String?)?.trim().isEmpty ?? true) {
      updates['email'] = email;
    }
    if ((existing['name'] as String?)?.trim().isEmpty ?? true) {
      updates['name'] = displayName;
    }

    if (updates.length > 1) {
      await userRef.update(updates);
    }

    final personalSnapshot = await personalRef.get();
    if (!personalSnapshot.exists) {
      await personalRef.set({
        'name': displayName,
        'email': email,
        'phone': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<UserCredential> signInAndCreateProfile() async {
    final credential = await signIn().timeout(
      const Duration(seconds: 90),
      onTimeout: () => throw FirebaseAuthException(
        code: 'google-sign-in-timeout',
        message: 'Google sign-in timed out. Please try again.',
      ),
    );
    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'Google sign-in completed without a Firebase user.',
      );
    }

    await ensureUserProfile(user);
    return credential;
  }

  Future<void> signOutGoogle() async {
    if (kIsWeb) return;
    if (!_initialized) return;
    await _googleSignIn.signOut();
  }
}
