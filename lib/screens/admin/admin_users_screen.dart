/// ---------------------------------------------------------------------------
/// ResUniq - admin_users_screen.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Administrator-only screens for dashboards, users, resumes, templates, and administrator previews.
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

import '../../models/user_profile.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';

/// AdminUsersScreen is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  Future<void> _changeRole(
    BuildContext context,
    UserProfile user,
  ) async {
    if (user.uid == FirebaseAuth.instance.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot change your own admin role here.'),
        ),
      );
      return;
    }

    final newRole = user.isAdmin ? 'user' : 'admin';
    final action = user.isAdmin ? 'Remove admin access' : 'Make admin';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$action?'),
        content: Text(
          'Change ${user.name.isEmpty ? user.email : user.name} to $newRole?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<AdminProvider>().setRole(user.uid, newRole);
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Unable to change role.')),
        );
      }
    }
  }

  Future<void> _changeDisabled(
    BuildContext context,
    UserProfile user,
  ) async {
    if (user.uid == FirebaseAuth.instance.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot disable your own account here.'),
        ),
      );
      return;
    }

    final disable = !user.disabled;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(disable ? 'Disable account?' : 'Enable account?'),
        content: Text(
          disable
              ? 'This will block ${user.email} from entering the app.'
              : 'This will allow ${user.email} to enter the app again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<AdminProvider>().setDisabled(user.uid, disable);
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Unable to update account.')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        title: const Text('Manage Users'),
        centerTitle: true,
      ),
      body: admin.usersError != null
          ? _AdminDataError(
              message: admin.usersError!,
              collection: 'users',
            )
          : admin.users.isEmpty
              ? const Center(child: Text('No users yet.'))
              : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                8,
                AppSpacing.page,
                32,
              ),
              itemCount: admin.users.length,
              itemBuilder: (context, index) {
                final user = admin.users[index];
                final isSelf = user.uid == currentUid;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryTint,
                        child: Icon(
                          user.isAdmin
                              ? Icons.admin_panel_settings_rounded
                              : Icons.person_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name.isEmpty
                                        ? '(No name)'
                                        : user.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelf) ...[
                                  const SizedBox(width: 6),
                                  const _Badge(
                                    label: 'You',
                                    color: AppColors.primary,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _Badge(
                                  label: user.isAdmin ? 'Admin' : 'User',
                                  color: user.isAdmin
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                if (user.disabled)
                                  const _Badge(
                                    label: 'Disabled',
                                    color: AppColors.error,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        enabled: !isSelf,
                        onSelected: (value) {
                          if (value == 'role') {
                            _changeRole(context, user);
                          } else if (value == 'disabled') {
                            _changeDisabled(context, user);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'role',
                            child: Text(
                              user.isAdmin
                                  ? 'Remove admin access'
                                  : 'Make admin',
                            ),
                          ),
                          PopupMenuItem(
                            value: 'disabled',
                            child: Text(
                              user.disabled
                                  ? 'Enable account'
                                  : 'Disable account',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// _Badge is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}


/// _AdminDataError is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _AdminDataError extends StatelessWidget {
  const _AdminDataError({
    required this.message,
    required this.collection,
  });

  final String message;
  final String collection;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load $collection',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Check that the admin account has a users/{Firebase Auth UID} '
              'document with role = admin and that the latest Firestore rules '
              'are published.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SelectableText(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
