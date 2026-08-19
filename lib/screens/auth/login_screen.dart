/// ---------------------------------------------------------------------------
/// ResUniq - login_screen.dart
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

import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_animations.dart';
import '../../services/google_auth_service.dart';
import 'check_auth_screen.dart';
import 'forgot_password_screen.dart';

/// LoginScreen is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class LoginScreen extends StatefulWidget {
  final VoidCallback showSignupScreen;
  const LoginScreen({super.key, required this.showSignupScreen});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// _LoginScreenState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await GoogleAuthService.instance.signInAndCreateProfile();

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CheckAuth()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;
      final wasCancelled =
          e.code == 'popup-closed-by-user' ||
          e.code == 'canceled' ||
          e.code == 'cancelled';
      if (wasCancelled) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      switch (e.code) {
        case 'popup-closed-by-user':
        case 'canceled':
        case 'cancelled':
          message = 'Google sign-in was cancelled.';
          break;
        case 'account-exists-with-different-credential':
          message =
              'An account already exists with this email using another sign-in method.';
          break;
        case 'network-request-failed':
          message = 'Check your internet connection and try again.';
          break;
        case 'google-sign-in-timeout':
          message = 'Google sign-in took too long. Please try again.';
          break;
        default:
          message = e.message ?? 'Unable to sign in with Google.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to sign in with Google: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Authentication succeeded. Immediately enter the auth gate so the
      // Firebase role is checked without requiring an app refresh.
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CheckAuth()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message != null
                ? "Incorrect email or password."
                : "Login failed. Try again later.",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.page,
                      ),
                      child: FadeSlideIn(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 28),
                          const SizedBox(height: 60),
                          Center(
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: Image.asset(
                                'assets/icon_of_app.png',
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Welcome Back',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue building your resume.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 40),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    hintText: 'Email',
                                    prefixIcon: Icon(
                                      Icons.mail_outline_rounded,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    final email = value?.trim() ?? '';
                                    if (email.isEmpty) return 'Please enter your email';
                                    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                                    return pattern.hasMatch(email) ? null : 'Please enter a valid email';
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscure,
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () => _obscure = !_obscure,
                                          ),
                                    ),
                                  ),
                                  validator: (value) =>
                                      (value == null || value.isEmpty)
                                          ? 'Please enter your password'
                                          : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  _isLoading
                                      ? null
                                      : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () {
                                      if (_formKey.currentState!.validate()) {
                                        _signIn();
                                      }
                                    },
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text('Login'),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'or',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            icon:
                                _isLoading
                                    ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.g_mobiledata_rounded,
                                      size: 26,
                                    ),
                            label: Text(
                              _isLoading
                                  ? 'Signing in...'
                                  : 'Continue with Google',
                            ),
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: Wrap(
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                GestureDetector(
                                  onTap: widget.showSignupScreen,
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
