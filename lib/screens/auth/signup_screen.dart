/// ---------------------------------------------------------------------------
/// ResUniq - signup_screen.dart
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
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_animations.dart';
import '../../services/google_auth_service.dart';
import 'check_auth_screen.dart';

/// SignupScreen is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class SignupScreen extends StatefulWidget {
  final VoidCallback showLoginScreen;
  const SignupScreen({super.key, required this.showLoginScreen});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

/// _SignupScreenState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addDetails(String uid, String name, String email) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    batch.set(db.collection('users').doc(uid), {
      'name': name,
      'email': email,
      'role': 'user',
      'disabled': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(db.collection('users_personal_details').doc(uid), {
      'name': name,
      'email': email,
      'phone': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> _signUpWithGoogle() async {
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
          message = 'Google sign-up was cancelled.';
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
          message = e.message ?? 'Unable to create your account with Google.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to sign up with Google: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);
    UserCredential? credential;

    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await _addDetails(
        credential.user!.uid,
        _nameController.text.trim(),
        _emailController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CheckAuth()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed')),
      );
    } on FirebaseException catch (e) {
      try {
        await credential?.user?.delete();
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to create user profile')),
      );
    } catch (e) {
      try {
        await credential?.user?.delete();
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to create account: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _obscure = true;
  bool _obscureConfirm = true;

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
                              child: Image.asset('assets/icon_of_app.png'),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Build a professional resume in minutes.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 40),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    hintText: 'Name',
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                  validator: (value) {
                                    final name = value?.trim() ?? '';
                                    if (name.isEmpty) return 'Please enter your name';
                                    if (name.length < 2) return 'Name must be at least 2 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    hintText: 'Email',
                                    prefixIcon: Icon(
                                      Icons.mail_outline_rounded,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
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
                                  validator: (value) {
                                    final password = value ?? '';
                                    if (password.isEmpty) return 'Please enter a password';
                                    if (password.length < 6) return 'Password must be at least 6 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  obscureText: _obscureConfirm,
                                  decoration: InputDecoration(
                                    hintText: 'Confirm Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () =>
                                                _obscureConfirm =
                                                    !_obscureConfirm,
                                          ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Please confirm your password';
                                    if (value != _passwordController.text) return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () {
                                      if (_formKey.currentState!.validate()) {
                                        _signUp();
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
                                    : const Text('Create Account'),
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
                            onPressed: _isLoading ? null : _signUpWithGoogle,
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
                                  ? 'Signing up...'
                                  : 'Continue with Google',
                            ),
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: Wrap(
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                GestureDetector(
                                  onTap: widget.showLoginScreen,
                                  child: const Text(
                                    'Login',
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
