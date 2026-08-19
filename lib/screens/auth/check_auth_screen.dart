/// ---------------------------------------------------------------------------
/// ResUniq - check_auth_screen.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Authentication screens. These pages handle login, signup, password reset, splash/auth checks, and Google Sign-In flows.
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
import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../home/home_screen.dart';
import 'auth_user_screen.dart';

/// Authentication gate.
///
/// Normal users:
///   users/{FirebaseAuth.uid}
///
/// Manually-created admins:
///   Firebase Authentication account + users/{FirebaseAuth.uid}
///
/// Admins are created outside the Flutter signup screen, but their Firestore
/// profile is still tied to the Authentication UID.
class CheckAuth extends StatelessWidget {
  const CheckAuth({super.key});

  /// Loads the Firestore profile using the Firebase Authentication UID.
  ///
  /// Normal users and manually-created admins use the same structure:
  ///
  /// users/{FirebaseAuth.uid}
  ///   email: ...
  ///   role: "user" | "admin"
  ///
  /// Admins are still created manually in Firebase Authentication. The app
  /// signup screen never needs to create an admin account.
  Future<UserProfile?> _loadProfile(User user) async {
    final db = FirebaseFirestore.instance;

    final snapshot = await db.collection('users').doc(user.uid).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return UserProfile.fromMap(user.uid, snapshot.data()!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final user = authSnapshot.data;
          if (user == null) {
            return const AuthUser();
          }

          return FutureBuilder<UserProfile?>(
            future: _loadProfile(user),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              if (profileSnapshot.hasError) {
                return _ProfileError(
                  message: profileSnapshot.error.toString(),
                );
              }

              final profile = profileSnapshot.data;

              if (profile == null) {
                return const _ProfileMissing();
              }

              if (profile.disabled) {
                return const _DisabledAccountView();
              }

              // The role is read from users/{FirebaseAuth.uid}.
              // A manually-created admin must have a UID-based profile.
              if (profile.role == 'admin') {
                return const AdminDashboardScreen();
              }

              return const HomeScreen();
            },
          );
        },
      ),
    );
  }
}

/// _ProfileMissing is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _ProfileMissing extends StatelessWidget {
  const _ProfileMissing();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              'Profile not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'No user profile was found for this account. '
              'For an admin, create users/{Firebase Auth UID} in Firestore '
              'and set role to "admin".',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context, rootNavigator: true)
                    .pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthUser()),
                  (_) => false,
                );
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}

/// _ProfileError is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message});

  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 14),
            Text(
              'Unable to check account role',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context, rootNavigator: true)
                    .pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthUser()),
                  (_) => false,
                );
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}

/// _DisabledAccountView is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _DisabledAccountView extends StatelessWidget {
  const _DisabledAccountView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.block_rounded,
              color: AppColors.error,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              'Account disabled',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your account has been disabled by an administrator.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context, rootNavigator: true)
                    .pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthUser()),
                  (_) => false,
                );
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
