/// ---------------------------------------------------------------------------
/// ResUniq - splash_screen.dart
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
import 'check_auth_screen.dart';
import '../../widgets/app_animations.dart';

/// SplashScreen is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// _SplashScreenState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    initializeApp();
  }

  Future<void> initializeApp() async {
    await Future.wait([Future.delayed(const Duration(seconds: 2)), _loadApp()]);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CheckAuth()),
    );
  }

  Future<void> _loadApp() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeSlideIn(
          duration: const Duration(milliseconds: 900),
          begin: const Offset(0, 0.08),
          child: Pulse(
            child: Image.asset(
              'assets/splash_screen_icon.png',
              width: 132,
              height: 132,
            ),
          ),
        ),
      ),
    );
  }
}
