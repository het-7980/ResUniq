/// ---------------------------------------------------------------------------
/// ResUniq - auth_user_screen.dart
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

import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// AuthUser is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class AuthUser extends StatefulWidget {
  const AuthUser({super.key});

  @override
  State<AuthUser> createState() => _AuthUserState();
}

/// _AuthUserState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _AuthUserState extends State<AuthUser> {
  bool showLoginPage = true;

  void toggleScreens() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginScreen(showSignupScreen: toggleScreens);
    } else {
      return SignupScreen(showLoginScreen: toggleScreens);
    }
  }
}
