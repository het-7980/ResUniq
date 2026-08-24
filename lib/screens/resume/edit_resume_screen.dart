/// ---------------------------------------------------------------------------
/// ResUniq - edit_resume_screen.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Resume creation, editing, template selection, and resume preview screens.
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
import '../../providers/resume_list_provider.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';
import 'create_resume_screen.dart';

/// EditResumeScreen is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class EditResumeScreen extends StatelessWidget {
  final ResumeDocument resume;

  const EditResumeScreen({super.key, required this.resume});

  static const _sections = [
    ('Personal Information', _hasPersonal),
    ('Education', _hasEducation),
    ('Experience', _hasExperience),
    ('Skills', _hasSkills),
    ('Projects', _hasProjects),
    ('Certifications', _hasCertifications),
    ('Languages', _hasLanguages),
    ('Interests', _hasInterests),
    ('References', _hasReferences),
  ];

  static bool _hasPersonal(ResumeDocument r) => !r.personal.isEmpty;
  static bool _hasEducation(ResumeDocument r) => r.education.isNotEmpty;
  static bool _hasExperience(ResumeDocument r) => r.experience.isNotEmpty;
  static bool _hasSkills(ResumeDocument r) => r.skills.isNotEmpty;
  static bool _hasProjects(ResumeDocument r) => r.projects.isNotEmpty;
  static bool _hasCertifications(ResumeDocument r) =>
      r.certifications.isNotEmpty;
  static bool _hasLanguages(ResumeDocument r) => r.languages.isNotEmpty;
  static bool _hasInterests(ResumeDocument r) => r.interests.isNotEmpty;
  static bool _hasReferences(ResumeDocument r) => r.references.isNotEmpty;

  void _openWizard(BuildContext context, int step) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateResumeScreen(
          existing: resume,
          initialStep: step,
        ),
      ),
    );
  }

  Future<void> _preview(BuildContext context) async {
    await PdfService.previewAndDownload(resume);
  }

  Future<void> _export(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing PDF...')),
    );
    await PdfService.share(resume);
  }

  Future<void> _duplicate(BuildContext context) async {
    await context.read<ResumeListProvider>().duplicate(resume);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume duplicated')),
      );
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Delete resume?'),
        content: Text('"${resume.title}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<ResumeListProvider>().delete(resume.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetTile(
                sheetContext,
                Icons.remove_red_eye_outlined,
                'Preview Resume',
                () => _preview(context),
              ),
              _sheetTile(
                sheetContext,
                Icons.picture_as_pdf_outlined,
                'Export PDF',
                () => _export(context),
              ),
              _sheetTile(
                sheetContext,
                Icons.copy_outlined,
                'Duplicate Resume',
                () => _duplicate(context),
              ),
              _sheetTile(
                sheetContext,
                Icons.delete_outline_rounded,
                'Delete Resume',
                () => _delete(context),
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetTile(
    BuildContext sheetContext,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textPrimary),
      title: Text(label, style: TextStyle(color: color)),
      onTap: () {
        Navigator.of(sheetContext).pop();
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(
          resume.title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showActionSheet(context),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            8,
            AppSpacing.page,
            120,
          ),
          children: [
            for (var index = 0; index < _sections.length; index++)
              Builder(
                builder: (context) {
                  final (label, hasContent) = _sections[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: InkWell(
                      onTap: () => _openWizard(context, index),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Icon(
                            hasContent(resume)
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: hasContent(resume)
                                ? AppColors.success
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            16,
          ),
          child: ElevatedButton(
            onPressed: () => _openWizard(context, 0),
            child: const Text('Save Changes'),
          ),
        ),
      ),
    );
  }
}
