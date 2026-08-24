/// ---------------------------------------------------------------------------
/// ResUniq - create_resume_screen.dart
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
import '../../providers/resume_form_provider.dart';
import '../../services/resume_repository.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_animations.dart';
import '../../widgets/form_field_group.dart';
import 'template_selection_screen.dart';

/// Modern step-by-step wizard for building (or editing) a resume.
/// Sections: Personal Information, Education, Experience, Skills, Projects,
/// Certifications, Languages, Interests, References. The objective is generated
/// automatically with the app's AI from the completed resume details.
///
/// Pass [existing] to edit a previously saved resume -- the same form
/// is reused for both create and edit flows.
class CreateResumeScreen extends StatelessWidget {
  final ResumeDocument? existing;
  final int initialStep;

  const CreateResumeScreen({super.key, this.existing, this.initialStep = 0});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ResumeRepository>();
    return ChangeNotifierProvider(
      create: (_) => ResumeFormProvider(repository, initial: existing),
      child: _WizardBody(
        isEditing: existing != null,
        initialStep: initialStep.clamp(0, _sections.length - 1).toInt(),
      ),
    );
  }
}

/// _StepSection is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _StepSection {
  final String title;
  final IconData icon;
  final String hint;
  const _StepSection(this.title, this.icon, this.hint);
}

const _sections = [
  _StepSection(
    'Personal Information',
    Icons.badge_outlined,
    'Your contact details and the role you are targeting.',
  ),
  _StepSection(
    'Education',
    Icons.school_outlined,
    'Degrees, institutions, years.',
  ),
  _StepSection(
    'Experience',
    Icons.work_outline_rounded,
    'Roles, companies, achievements.',
  ),
  _StepSection('Skills', Icons.bolt_outlined, 'Key technical & soft skills.'),
  _StepSection(
    'Projects',
    Icons.folder_open_outlined,
    'Notable projects and outcomes.',
  ),
  _StepSection(
    'Certifications',
    Icons.verified_outlined,
    'Licenses and certifications.',
  ),
  _StepSection('Languages', Icons.translate_rounded, 'Languages you speak.'),
  _StepSection(
    'Interests',
    Icons.favorite_border_rounded,
    'Hobbies and interests.',
  ),
  _StepSection(
    'References',
    Icons.people_outline_rounded,
    'People who can vouch for you.',
  ),
  _StepSection(
    'Custom Fields',
    Icons.add_box_outlined,
    'Add your own resume sections, such as Awards or Publications.',
  ),
];

/// _WizardBody is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _WizardBody extends StatefulWidget {
  final bool isEditing;
  final int initialStep;

  const _WizardBody({required this.isEditing, required this.initialStep});

  @override
  State<_WizardBody> createState() => _WizardBodyState();
}

/// _WizardBodyState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _WizardBodyState extends State<_WizardBody> {
  late int _step;
  bool _generatingSummary = false;
  final _stepFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
  }

  double get _progress => (_step + 1) / _sections.length;

  Future<void> _saveDraft(BuildContext context) async {
    await context.read<ResumeFormProvider>().save();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft saved')));
    }
  }

  Future<void> _next(BuildContext context) async {
    final form = context.read<ResumeFormProvider>();

    final valid = _stepFormKey.currentState?.validate() ?? true;
    if (!valid) return;

    if (!_validateTagSection(form.draft)) return;

    if (_step < _sections.length - 1) {
      setState(() => _step++);
      return;
    }

    // Keep an existing AI-generated objective when editing instead of
    // generating a new paragraph every time the user chooses a template.
    if (form.draft.objective.trim().isNotEmpty) {
      await form.save();
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TemplateSelectionScreen(resume: form.draft),
        ),
      );
      return;
    }

    final gemini = GeminiService();
    if (!gemini.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI service configuration is missing.')),
      );
      return;
    }

    setState(() => _generatingSummary = true);
    try {
      final objective = await gemini.generateObjective(
        resumeDetails: _objectiveInput(form.draft),
      );

      if (objective.trim().isEmpty) {
        throw Exception(
          'The AI service returned an empty professional summary.',
        );
      }

      form.setObjective(objective.trim());
      await form.save();
      if (!context.mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TemplateSelectionScreen(resume: form.draft),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI summary could not be generated: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingSummary = false);
    }
  }

  bool _validateTagSection(ResumeDocument resume) {
    if (_step == 3 && resume.skills.isEmpty) {
      _showSectionError('Please add at least one skill.');
      return false;
    }
    if (_step == 6 && resume.languages.isEmpty) {
      _showSectionError('Please add at least one language.');
      return false;
    }
    if (_step == 7 && resume.interests.isEmpty) {
      _showSectionError('Please add at least one interest.');
      return false;
    }
    if (_step == 9) {
      for (final field in resume.customFields) {
        if (field.label.trim().isEmpty || field.value.trim().isEmpty) {
          _showSectionError(
            'Please complete or remove every custom field before continuing.',
          );
          return false;
        }
      }
    }
    return true;
  }

  void _showSectionError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, dynamic> _objectiveInput(ResumeDocument resume) {
    final map = resume.toMap();
    map.remove('objective');
    map.remove('createdAt');
    map.remove('updatedAt');
    map.remove('ownerId');
    return map;
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final section = _sections[_step];

    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top bar + progress
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    16,
                    AppSpacing.page,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _back,
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.isEditing
                                  ? 'Edit Resume'
                                  : 'Create Resume',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Center(
                              child: Text(
                                '${_step + 1}/${_sections.length}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 6,
                          backgroundColor: AppColors.primaryTintStrong,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Step content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      8,
                      AppSpacing.page,
                      32,
                    ),
                    child: Form(
                      key: _stepFormKey,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0.025, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          );
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          key: ValueKey(_step),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_step == 0) ...[
                              Text(
                                'Resume Name',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              LabeledField(
                                label: 'e.g. Software Developer Resume',
                                initialValue:
                                    context
                                        .read<ResumeFormProvider>()
                                        .draft
                                        .title,
                                onChanged:
                                    context.read<ResumeFormProvider>().setTitle,
                                requiredField: true,
                              ),
                              const SizedBox(height: 8),
                            ],
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              child: Icon(
                                section.icon,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              section.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              section.hint,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                            _StepForm(step: _step),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Sticky bottom bar: Save (icon) + Continue
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    0,
                    AppSpacing.page,
                    20,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () => _saveDraft(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: const Icon(
                            Icons.save_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _generatingSummary ? null : () => _next(context),
                          child:
                              _generatingSummary &&
                                      _step == _sections.length - 1
                                  ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text('Generating...'),
                                    ],
                                  )
                                  : Text(
                                    _step == _sections.length - 1
                                        ? 'Choose Template'
                                        : 'Continue',
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_generatingSummary) ...[
            const ModalBarrier(dismissible: false, color: Colors.black54),
            Center(
              child: Container(
                width: 310,
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadius.lg),
                  ),
                  boxShadow: AppShadows.soft,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: AppLoadingIndicator(size: 26),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Creating your resume summary',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'AI is turning your details into a professional paragraph.\nPlease wait a moment...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const ClipRRect(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.pill),
                      ),
                      child: LinearProgressIndicator(minHeight: 5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Renders the correct set of fields for the current wizard step, all
/// bound directly to [ResumeFormProvider].
class _StepForm extends StatelessWidget {
  final int step;
  const _StepForm({required this.step});

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ResumeFormProvider>();
    final draft = form.draft;

    switch (step) {
      case 0: // Personal Information
        final p = draft.personal;
        return Column(
          children: [
            LabeledField(
              label: 'Full Name',
              initialValue: p.fullName,
              requiredField: true,
              onChanged:
                  (v) => form.updatePersonal((pi) => pi.copyWith(fullName: v)),
            ),
            LabeledField(
              label: 'Target Job Role',
              initialValue: p.jobRole,
              requiredField: true,
              onChanged:
                  (v) => form.updatePersonal((pi) => pi.copyWith(jobRole: v)),
            ),
            LabeledField(
              label: 'Email',
              initialValue: p.email,
              requiredField: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                final email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                return email.hasMatch(value)
                    ? null
                    : 'Please enter a valid email';
              },
              keyboardType: TextInputType.emailAddress,
              onChanged:
                  (v) => form.updatePersonal((pi) => pi.copyWith(email: v)),
            ),
            LabeledField(
              label: 'Phone',
              initialValue: p.phone,
              requiredField: true,
              keyboardType: TextInputType.phone,
              validator: (value) {
                final phone = value?.trim() ?? '';
                if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
                  return 'Phone number must be exactly 10 digits';
                }
                return null;
              },
              onChanged:
                  (v) => form.updatePersonal((pi) => pi.copyWith(phone: v)),
            ),
            LabeledField(
              label: 'Location',
              initialValue: p.location,
              onChanged:
                  (v) => form.updatePersonal((pi) => pi.copyWith(location: v)),
            ),
            LabeledField(
              label: 'Website / LinkedIn',
              initialValue: p.website,
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                final uri = Uri.tryParse(value);
                return uri != null &&
                        (uri.hasScheme || value.startsWith('www.'))
                    ? null
                    : 'Please enter a valid website or LinkedIn URL';
              },
              onChanged:
                  (v) => form.updatePersonal((pi) => pi.copyWith(website: v)),
            ),
          ],
        );

      case 1: // Education
        return Column(
          children: [
            for (final e in draft.education)
              EntryCard(
                onRemove: () => form.removeEducation(e.id),
                children: [
                  LabeledField(
                    label: 'School / University',
                    initialValue: e.school,
                    requiredField: true,
                    onChanged:
                        (v) => form.updateEducation(
                          e.id,
                          (x) => x.copyWith(school: v),
                        ),
                  ),
                  LabeledField(
                    label: 'Degree',
                    initialValue: e.degree,
                    requiredField: true,
                    onChanged:
                        (v) => form.updateEducation(
                          e.id,
                          (x) => x.copyWith(degree: v),
                        ),
                  ),
                  LabeledField(
                    label: 'Years (e.g. 2020 - 2024)',
                    initialValue: e.years,
                    requiredField: true,
                    validator: (value) {
                      final years = value?.trim() ?? '';
                      final pattern = RegExp(
                        r'^\d{4}\s*-\s*(\d{4}|Present)$',
                        caseSensitive: false,
                      );
                      return pattern.hasMatch(years)
                          ? null
                          : 'Use format YYYY - YYYY or YYYY - Present';
                    },
                    onChanged:
                        (v) => form.updateEducation(
                          e.id,
                          (x) => x.copyWith(years: v),
                        ),
                  ),
                ],
              ),
            AddEntryButton(
              label: 'Add Education',
              onPressed: form.addEducation,
            ),
          ],
        );

      case 2: // Experience
        return Column(
          children: [
            for (final e in draft.experience)
              EntryCard(
                onRemove: () => form.removeExperience(e.id),
                children: [
                  LabeledField(
                    label: 'Job Title',
                    initialValue: e.role,
                    requiredField: true,
                    onChanged:
                        (v) => form.updateExperience(
                          e.id,
                          (x) => x.copyWith(role: v),
                        ),
                  ),
                  LabeledField(
                    label: 'Company',
                    initialValue: e.company,
                    requiredField: true,
                    onChanged:
                        (v) => form.updateExperience(
                          e.id,
                          (x) => x.copyWith(company: v),
                        ),
                  ),
                  LabeledField(
                    label: 'Duration (e.g. Jan 2022 - Present)',
                    initialValue: e.duration,
                    requiredField: true,
                    onChanged:
                        (v) => form.updateExperience(
                          e.id,
                          (x) => x.copyWith(duration: v),
                        ),
                  ),
                  LabeledField(
                    label: 'Description / achievements',
                    initialValue: e.description,
                    requiredField: true,
                    maxLines: 3,
                    onChanged:
                        (v) => form.updateExperience(
                          e.id,
                          (x) => x.copyWith(description: v),
                        ),
                  ),
                ],
              ),
            AddEntryButton(
              label: 'Add Experience',
              onPressed: form.addExperience,
            ),
          ],
        );

      case 3: // Skills
        return ChipEntryField(
          hint: 'Add a skill and press +',
          values: draft.skills,
          onAdd: form.addSkill,
          onRemoveAt: form.removeSkillAt,
        );

      case 4: // Projects
        return Column(
          children: [
            for (final e in draft.projects)
              EntryCard(
                onRemove: () => form.removeProject(e.id),
                children: [
                  LabeledField(
                    label: 'Project Name',
                    initialValue: e.name,
                    requiredField: true,
                    onChanged:
                        (v) => form.updateProject(
                          e.id,
                          (x) => x.copyWith(name: v),
                        ),
                  ),
                  LabeledField(
                    label: 'Description',
                    initialValue: e.description,
                    requiredField: true,
                    maxLines: 3,
                    onChanged:
                        (v) => form.updateProject(
                          e.id,
                          (x) => x.copyWith(description: v),
                        ),
                  ),
                  LabeledField(
                    label: 'Link (optional)',
                    initialValue: e.link,
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final uri = Uri.tryParse(value);
                      return uri != null &&
                              (uri.hasScheme || value.startsWith('www.'))
                          ? null
                          : 'Please enter a valid project URL';
                    },
                    onChanged:
                        (v) => form.updateProject(
                          e.id,
                          (x) => x.copyWith(link: v),
                        ),
                  ),
                ],
              ),
            AddEntryButton(label: 'Add Project', onPressed: form.addProject),
          ],
        );

      case 5: // Certifications
        return Column(
          children: [
            for (final e in draft.certifications)
              EntryCard(
                onRemove: () => form.removeCertification(e.id),
                children: [
                  LabeledField(
                    label: 'Certification Name',
                    initialValue: e.name,
                    requiredField: true,
                    onChanged:
                        (v) => form.updateCertification(
                          e.id,
                          (x) => x.copyWith(name: v),
                        ),
                  ),
                  LabeledField(
                    label: 'Issuer',
                    initialValue: e.issuer,
                    requiredField: true,
                    onChanged:
                        (v) => form.updateCertification(
                          e.id,
                          (x) => x.copyWith(issuer: v),
                        ),
                  ),
                  LabeledField(
                    label: 'Year',
                    initialValue: e.year,
                    requiredField: true,
                    validator: (value) {
                      final year = value?.trim() ?? '';
                      return RegExp(r'^\d{4}$').hasMatch(year)
                          ? null
                          : 'Year must be 4 digits';
                    },
                    onChanged:
                        (v) => form.updateCertification(
                          e.id,
                          (x) => x.copyWith(year: v),
                        ),
                  ),
                ],
              ),
            AddEntryButton(
              label: 'Add Certification',
              onPressed: form.addCertification,
            ),
          ],
        );

      case 6: // Languages
        return ChipEntryField(
          hint: 'Add a language and press +',
          values: draft.languages,
          onAdd: form.addLanguage,
          onRemoveAt: form.removeLanguageAt,
        );

      case 7: // Interests
        return ChipEntryField(
          hint: 'Add an interest and press +',
          values: draft.interests,
          onAdd: form.addInterest,
          onRemoveAt: form.removeInterestAt,
        );

      case 8: // References
        return Column(
          children: [
            for (final e in draft.references)
              EntryCard(
                onRemove: () => form.removeReference(e.id),
                children: [
                  LabeledField(
                    label: 'Name',
                    initialValue: e.name,
                    requiredField: true,
                    onChanged:
                        (v) => form.updateReference(
                          e.id,
                          (x) => x.copyWith(name: v),
                        ),
                  ),
                  LabeledField(
                    label: 'Relation (e.g. Manager at Acme)',
                    initialValue: e.relation,
                    requiredField: true,
                    onChanged:
                        (v) => form.updateReference(
                          e.id,
                          (x) => x.copyWith(relation: v),
                        ),
                  ),
                  LabeledField(
                    label: 'Contact (email or phone)',
                    initialValue: e.contact,
                    requiredField: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a contact';
                      }
                      final email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                      final phone = RegExp(r'^\d{10}$');
                      return email.hasMatch(value) || phone.hasMatch(value)
                          ? null
                          : 'Enter a valid email or exactly 10-digit phone number';
                    },
                    onChanged:
                        (v) => form.updateReference(
                          e.id,
                          (x) => x.copyWith(contact: v),
                        ),
                  ),
                ],
              ),
            AddEntryButton(
              label: 'Add Reference',
              onPressed: form.addReference,
            ),
          ],
        );

      case 9: // Custom Fields
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (draft.customFields.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Text(
                  'Add any extra section you want on your resume. '
                  'Examples: Awards, Publications, Volunteer Work, Achievements.',
                ),
              ),
            for (final field in draft.customFields)
              EntryCard(
                onRemove: () => form.removeCustomField(field.id),
                children: [
                  LabeledField(
                    label: 'Field Title',
                    initialValue: field.label,
                    requiredField: true,
                    onChanged: (v) => form.updateCustomField(
                      field.id,
                      (x) => x.copyWith(label: v.trim()),
                    ),
                  ),
                  LabeledField(
                    label: 'Content',
                    initialValue: field.value,
                    requiredField: true,
                    maxLines: 5,
                    onChanged: (v) => form.updateCustomField(
                      field.id,
                      (x) => x.copyWith(value: v.trim()),
                    ),
                  ),
                ],
              ),
            AddEntryButton(
              label: 'Add Custom Field',
              onPressed: form.addCustomField,
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
