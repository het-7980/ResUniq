/// ---------------------------------------------------------------------------
/// ResUniq - profile_screen.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// User profile display and profile-editing screens.
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

import '../../providers/user_profile_provider.dart';
import '../../services/account_deletion_service.dart';
import '../../services/password_service.dart';
import '../../services/personal_details_service.dart';
import '../../services/profile_picture_service.dart';
import 'edit_profile_screen.dart';
import '../auth/auth_user_screen.dart';
import '../../theme/app_theme.dart';

/// ProfileScreen is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your profile and all of your '
          'resumes. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !context.mounted) return;

    final providers = user.providerData.map((info) => info.providerId).toSet();
    final isGoogleUser = providers.contains('google.com');
    final isPasswordUser = providers.contains('password');

    String? password;

    if (isPasswordUser) {
      final passwordController = TextEditingController();

      password = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm your password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = passwordController.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      passwordController.dispose();

      if (password == null || password!.isEmpty || !context.mounted) {
        return;
      }
    } else if (isGoogleUser) {
      // Google users do not have an app password. The deletion service will
      // reauthenticate them with a fresh Google credential instead.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This account uses an unsupported sign-in method. '
            'Please sign in again before deleting it.',
          ),
        ),
      );
      return;
    }

    final progress = ValueNotifier<String>('Starting...');

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: ValueListenableBuilder<String>(
            valueListenable: progress,
            builder: (_, message, __) => Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 18),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        ),
      ),
    );

    var progressDialogOpen = true;

    Future<void> closeProgressDialog() async {
      if (!progressDialogOpen) return;
      progressDialogOpen = false;

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    try {
      await AccountDeletionService().deleteAccount(
        password: password,
        onProgress: (message) => progress.value = message,
      );

      await closeProgressDialog();
      progress.dispose();

      if (!context.mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthUser()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      await closeProgressDialog();
      progress.dispose();

      if (!context.mounted) return;

      final message = switch (e.code) {
        'wrong-password' || 'invalid-credential' =>
          isGoogleUser
              ? 'Google verification failed. Please try again.'
              : 'The password is incorrect.',
        'too-many-requests' =>
          'Too many attempts. Please try again later.',
        'network-request-failed' =>
          'Network error. Check your internet connection.',
        'canceled' =>
          'Google verification was cancelled.',
        'google-reauthentication-failed' =>
          'Unable to verify your Google account. Please try again.',
        'requires-recent-login' =>
          isGoogleUser
              ? 'Google verification is required. Please try again.'
              : 'Please enter your password again to verify your account.',
        _ => e.message ?? 'Unable to delete the account.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      await closeProgressDialog();
      progress.dispose();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete account: $e')),
      );
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final passwords = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Use at least 6 characters.',
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final current = currentPasswordController.text;
              final next = newPasswordController.text;
              final confirm = confirmPasswordController.text;

              if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all password fields.'),
                  ),
                );
                return;
              }

              if (next.length < 6) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('New password must be at least 6 characters.'),
                  ),
                );
                return;
              }

              if (next != confirm) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('New passwords do not match.'),
                  ),
                );
                return;
              }

              if (current == next) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'New password must be different from the current password.',
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext, [current, next]);
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (passwords == null || !context.mounted) return;

    final progress = ValueNotifier<String>('Updating password...');

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: ValueListenableBuilder<String>(
            valueListenable: progress,
            builder: (_, message, __) => Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 18),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await PasswordService().changePassword(
        currentPassword: passwords[0],
        newPassword: passwords[1],
      );

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      progress.dispose();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      progress.dispose();

      if (!context.mounted) return;

      final message = switch (e.code) {
        'wrong-password' || 'invalid-credential' =>
          'The current password is incorrect.',
        'weak-password' =>
          'The new password is too weak. Use at least 6 characters.',
        'requires-recent-login' =>
          'Please sign in again and try changing your password.',
        'network-request-failed' =>
          'Network error. Check your internet connection.',
        'too-many-requests' =>
          'Too many attempts. Please try again later.',
        _ => e.message ?? 'Unable to change the password.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on StateError catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      progress.dispose();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      progress.dispose();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to change the password: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileProvider>().profile;
    final name = (profile?.name.isNotEmpty ?? false) ? profile!.name : 'there';
    final email = profile?.email ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return SafeArea(
      bottom: false,
      child: FutureBuilder<Map<String, dynamic>?>(
        future: uid == null ? Future.value(null) : PersonalDetailsService().getDetails(uid),
        builder: (context, snapshot) {
          final details = snapshot.data ?? {};
          final phone = details['phone']?.toString() ?? '';
          final imageValue = details['profileImageUrl']?.toString() ?? '';
          final imageBytes = ProfilePictureService.decode(imageValue);

          var complete = 0;
          if (name.trim().isNotEmpty && name != 'there') complete++;
          if (email.trim().isNotEmpty) complete++;
          if (phone.trim().isNotEmpty) complete++;
          if (imageBytes != null) complete++;
          final progress = complete / 4;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              18,
              AppSpacing.page,
              110,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'My Profile',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Manage your personal information and account.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: .65),
                            ),
                      ),
                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryTint,
                              Theme.of(context).cardColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: .15),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: .35),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: Theme.of(context).cardColor,
                                backgroundImage: imageBytes != null
                                    ? MemoryImage(imageBytes)
                                    : null,
                                child: imageBytes == null
                                    ? const Icon(
                                        Icons.person_rounded,
                                        size: 46,
                                        color: AppColors.primary,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 13),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                email,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: .65),
                                    ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const EditProfileScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                label: const Text('Edit Profile'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withValues(alpha: .6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified_user_outlined,
                                  color: AppColors.primary,
                                  size: 21,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'Profile completeness',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).round()}%',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 7,
                                backgroundColor: AppColors.primaryTint,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              progress >= 1
                                  ? 'Your profile is ready for your resumes.'
                                  : 'Add your phone number and photo to complete your profile.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        'Personal Information',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),

                      _ProfileInfoCard(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: email.isEmpty ? 'Not available' : email,
                      ),
                      const SizedBox(height: 9),
                      _ProfileInfoCard(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: phone.isEmpty ? 'Not added yet' : phone,
                      ),

                      const SizedBox(height: 22),

                      Text(
                        'Account & Security',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),

                      _ProfileActionCard(
                        icon: Icons.lock_outline_rounded,
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap: () => _changePassword(context),
                      ),
                      const SizedBox(height: 10),

                      OutlinedButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!context.mounted) return;
                          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthUser()),
                            (_) => false,
                          );
                        },
                        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                        label: const Text(
                          'Logout',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: BorderSide(color: AppColors.error.withValues(alpha: .5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => _deleteAccount(context),
                        child: const Text(
                          'Delete Account',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// _ProfileInfoCard is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: .55),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// _ProfileActionCard is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(alpha: 0.65),
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
