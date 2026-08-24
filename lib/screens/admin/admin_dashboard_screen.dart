/// ---------------------------------------------------------------------------
/// ResUniq - admin_dashboard_screen.dart
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

import '../../providers/admin_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_animations.dart';
import '../auth/auth_user_screen.dart';
import 'admin_resumes_screen.dart';
import 'admin_form_fields_screen.dart';
import 'admin_users_screen.dart';
import 'admin_templates_screen.dart';

/// AdminDashboardScreen is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileProvider>().profile;

    if (profile == null || !profile.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('You do not have admin access.')),
      );
    }

    // Keep AdminProvider above the dashboard and pass the same instance to
    // pushed management routes. A Provider placed inside the dashboard body
    // is not automatically visible to routes pushed onto the Navigator.
    return ChangeNotifierProvider(
      create: (context) => AdminProvider(
        context.read<AdminRepository>(),
      ),
      child: const _AdminDashboardBody(),
    );
  }
}

/// _AdminDashboardBody is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _AdminDashboardBody extends StatelessWidget {
  const _AdminDashboardBody();

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthUser()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final profile = context.watch<UserProfileProvider>().profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        titleSpacing: AppSpacing.page,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Dashboard'),
            if (profile != null)
              Text(
                profile.name.isEmpty ? profile.email : profile.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: admin.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : FadeSlideIn(
              duration: const Duration(milliseconds: 460),
              child: RefreshIndicator(
              onRefresh: () async {
                // The admin data is live through Firestore snapshots.
                // A short delay gives the pull-to-refresh gesture useful
                // feedback while the streams remain the source of truth.
                await Future<void>.delayed(const Duration(milliseconds: 250));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  8,
                  AppSpacing.page,
                  32,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Administrator',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Manage users and resumes',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Users',
                          value: '${admin.totalUsers}',
                          icon: Icons.people_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Admins',
                          value: '${admin.totalAdmins}',
                          icon: Icons.shield_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Resumes',
                          value: '${admin.totalResumes}',
                          icon: Icons.description_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Completed',
                          value: '${admin.completeResumes}',
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Management',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _ManagementTile(
                    icon: Icons.people_outline_rounded,
                    title: 'Manage Users',
                    subtitle: 'View users and manage roles or account access',
                    onTap: () {
                      final adminProvider = context.read<AdminProvider>();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: adminProvider,
                            child: const AdminUsersScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ManagementTile(
                    icon: Icons.description_outlined,
                    title: 'Manage Resumes',
                    subtitle: 'View and remove resumes across the app',
                    onTap: () {
                      final adminProvider = context.read<AdminProvider>();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: adminProvider,
                            child: const AdminResumesScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ManagementTile(
                    icon: Icons.dashboard_customize_outlined,
                    title: 'Manage Templates',
                    subtitle: 'View all resume templates available in ResUniq',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminTemplatesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ManagementTile(
                    icon: Icons.tune_rounded,
                    title: 'Manage Form Fields',
                    subtitle:
                        'Add, edit, enable, disable, and reorder resume form fields',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminFormFieldsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ),
    );
  }
}

/// _StatCard is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// _ManagementTile is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _ManagementTile extends StatelessWidget {
  const _ManagementTile({
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
