/// ---------------------------------------------------------------------------
/// ResUniq - main.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Application entry point. Initializes Firebase and app-wide providers, then starts the ResUniq Flutter application.
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'providers/resume_list_provider.dart';
import 'providers/user_profile_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'services/admin_repository.dart';
import 'services/firebase_resume_repository.dart';
import 'services/firestore_admin_repository.dart';
import 'services/firestore_user_repository.dart';
import 'services/local_resume_repository.dart';
import 'services/google_auth_service.dart';
import 'services/resume_repository.dart';
import 'services/user_repository.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await GoogleAuthService.instance.initialize();

  runApp(const ResumeBuilderApp());
}

/// ResumeBuilderApp is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class ResumeBuilderApp extends StatelessWidget {
  const ResumeBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
        ),

        ProxyProvider<User?, ResumeRepository>(
          update:
              (context, user, previous) =>
                  user != null
                      ? FirebaseResumeRepository(userId: user.uid)
                      : LocalResumeRepository(),
        ),
        ChangeNotifierProxyProvider<ResumeRepository, ResumeListProvider>(
          create:
              (context) => ResumeListProvider(context.read<ResumeRepository>()),
          update:
              (context, repository, previous) =>
                  previous != null && previous.repository == repository
                      ? previous
                      : ResumeListProvider(repository),
        ),

        ProxyProvider<User?, UserRepository?>(
          update:
              (context, user, previous) =>
                  user != null ? FirestoreUserRepository(uid: user.uid) : null,
        ),
        ChangeNotifierProxyProvider<UserRepository?, UserProfileProvider>(
          create:
              (context) => UserProfileProvider(context.read<UserRepository?>()),
          update:
              (context, repository, previous) =>
                  UserProfileProvider(repository),
        ),

        // Admin repository is only consumed by AdminProvider after a
        // confirmed admin reaches the admin dashboard.
        Provider<AdminRepository>(create: (_) => FirestoreAdminRepository()),
      ],
      child: MaterialApp(
        title: 'ResUniq',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
