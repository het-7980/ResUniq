/// ---------------------------------------------------------------------------
/// ResUniq - admin_resumes_screen.dart
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/resume_document.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import 'admin_resume_preview_screen.dart';

/// AdminResumesScreen is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class AdminResumesScreen extends StatelessWidget {
  const AdminResumesScreen({super.key});

  String _ownerLabel(AdminProvider admin, String? ownerId) {
    if (ownerId == null || ownerId.isEmpty) return 'Unknown owner';

    final matches = admin.users.where((u) => u.uid == ownerId);
    if (matches.isEmpty) return ownerId;

    final user = matches.first;
    return user.name.isNotEmpty ? user.name : user.email;
  }

  String _date(DateTime value) {
    final d = value.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _delete(
    BuildContext context,
    ResumeDocument resume,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete resume?'),
        content: Text(
          '"${resume.title}" will be permanently deleted from Firestore.',
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

    try {
      await context.read<AdminProvider>().deleteResume(resume.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete resume: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        title: const Text('Manage Resumes'),
        centerTitle: true,
      ),
      body: admin.resumesError != null
          ? _AdminResumeDataError(
              message: admin.resumesError!,
            )
          : admin.resumes.isEmpty
              ? const Center(child: Text('No resumes yet.'))
              : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                8,
                AppSpacing.page,
                32,
              ),
              itemCount: admin.resumes.length,
              itemBuilder: (context, index) {
                final resume = admin.resumes[index];

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
                      Container(
                        width: 46,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resume.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Owner: ${_ownerLabel(admin, resume.ownerId)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Updated ${_date(resume.updatedAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Preview PDF',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminResumePreviewScreen(resume: resume),
                            ),
                          );
                        },
                        icon: const Icon(Icons.remove_red_eye_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete resume',
                        onPressed: () => _delete(context, resume),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}


/// _AdminResumeDataError is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _AdminResumeDataError extends StatelessWidget {
  const _AdminResumeDataError({required this.message});

  final String message;

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
              'Unable to load resumes',
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
