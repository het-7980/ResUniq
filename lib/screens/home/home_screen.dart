/// ---------------------------------------------------------------------------
/// ResUniq - home_screen.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Main user home screen and navigation for the resume-builder experience.
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

import '../../models/resume_document.dart';
import '../../providers/resume_list_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../services/personal_details_service.dart';
import '../../services/profile_picture_service.dart';
import '../../services/template_service.dart';
import '../../services/pdf_generator.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_animations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/floating_bottom_nav.dart';
import '../../widgets/profile_summary_card.dart';
import '../../widgets/resume_card.dart';
import '../profile/profile_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../resume/create_resume_screen.dart';
import '../resume/edit_resume_screen.dart';
import '../resume/user_template_preview_screen.dart';

/// Root shell that hosts Home / Create / Profile behind the floating
/// bottom navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// _HomeScreenState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  void _goToTab(int index) {
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateResumeScreen()),
      );
      return;
    }
    setState(() => _tabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final body = _tabIndex == 2 ? const ProfileScreen() : const _HomeDashboard();

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: body,
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: _tabIndex,
        onTap: _goToTab,
      ),
    );
  }
}

/// _HomeDashboard is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard();

  /// Returns "Good Morning," / "Good Afternoon," / "Good Evening,"
  /// based on the device's current local time.
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Future<void> _confirmDelete(BuildContext context, ResumeDocument resume) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Delete resume?'),
        content: Text('"${resume.title}" will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ResumeListProvider>().delete(resume.id);
    }
  }

  Future<void> _renameResume(
    BuildContext context,
    ResumeDocument resume,
  ) async {
    final controller = TextEditingController(text: resume.title);

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Resume'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Resume name',
            hintText: 'e.g. Software Developer Resume',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value == null || value.isEmpty || !context.mounted) return;

    await context.read<ResumeListProvider>().save(
          resume.copyWith(title: value),
        );
  }

  Future<void> _previewResume(BuildContext context, ResumeDocument resume) async {
    final templateId = resume.templateId.trim();
    if (!templateId.startsWith('ai_')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This resume does not have an available preview template. Please choose a template first.'),
          ),
        );
      }
      return;
    }

    try {
      final template = await TemplateService().getGeneratedTemplate(templateId);
      if (template == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The selected template is no longer available. Please choose another template.'),
            ),
          );
        }
        return;
      }

      PdfGenerator.registerGeneratedTemplates([template]);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UserTemplatePreviewScreen(
            resume: resume.copyWith(templateId: template.id),
            template: template,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open preview: $e')),
        );
      }
    }
  }

  Future<void> _download(BuildContext context, ResumeDocument resume) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing PDF...')),
    );
    await PdfService.share(resume);
  }

  Future<void> _showResumePicker(
    BuildContext context,
    List<ResumeDocument> resumes,
  ) async {
    if (resumes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a resume first.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<ResumeDocument>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Choose a Resume',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Select the resume you want to edit.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: resumes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final resume = resumes[index];
                      return Material(
                        color: AppColors.secondaryBackground,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: () => Navigator.pop(sheetContext, resume),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryTint,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        resume.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${resume.templateId} • ${(resume.completion * 100).round()}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
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
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditResumeScreen(resume: selected),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listProvider = context.watch<ResumeListProvider>();
    final resumes = listProvider.resumes;
    final profile = context.watch<UserProfileProvider>().profile;
    final displayName = (profile?.name.isNotEmpty ?? false) ? profile!.name : 'there';

    return SafeArea(
      bottom: false,
      child: FadeSlideIn(
        duration: const Duration(milliseconds: 480),
        child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 20, AppSpacing.page, 120),
        children: [
          // Top greeting row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(), style: Theme.of(context).textTheme.bodyMedium),
                    Text(displayName, style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ),
              FutureBuilder<Map<String, dynamic>?>(
                future: FirebaseAuth.instance.currentUser == null
                    ? Future.value(null)
                    : PersonalDetailsService().getDetails(
                        FirebaseAuth.instance.currentUser!.uid,
                      ),
                builder: (context, snapshot) {
                  final imageValue =
                      snapshot.data?['profileImageUrl']?.toString() ?? '';
                  final imageBytes =
                      ProfilePictureService.decode(imageValue);

                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryTint,
                    backgroundImage:
                        imageBytes != null ? MemoryImage(imageBytes) : null,
                    child: imageBytes == null
                        ? const Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Profile summary card
          ProfileSummaryCard(
            name: displayName,
            email: profile?.email ?? '',
            profession: '',
            resumeCount: resumes.length,
            completion: listProvider.averageCompletion,
            onEditProfile: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
          const SizedBox(height: 24),

          // Quick actions
          PrimaryActionButton(
            label: 'Create New Resume',
            icon: Icons.add_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateResumeScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          SecondaryActionButton(
            label: 'Edit Existing Resume',
            icon: Icons.edit_outlined,
            onPressed: () => _showResumePicker(context, resumes),
          ),
          const SizedBox(height: 32),

          // My Resumes section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Resumes', style: Theme.of(context).textTheme.titleLarge),
              if (resumes.isNotEmpty)
                TextButton(
                  onPressed: () => _showResumePicker(context, resumes),
                  child: const Text('See all'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (listProvider.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (resumes.isEmpty)
            EmptyResumesState(
              onCreate: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateResumeScreen()),
                );
              },
            )
          else
            ...resumes.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ResumeCard(
                  resume: r,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EditResumeScreen(resume: r)),
                    );
                  },
                  onEdit: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreateResumeScreen(existing: r),
                      ),
                    );
                  },
                  onRename: () => _renameResume(context, r),
                  onDuplicate: () => context.read<ResumeListProvider>().duplicate(r),
                  onDownload: () => _download(context, r),
                  onPreview: () => _previewResume(context, r),
                  onDelete: () => _confirmDelete(context, r),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}
