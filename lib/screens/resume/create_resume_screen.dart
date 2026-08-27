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

import '../../models/form_field_definition.dart';
import '../../models/resume_document.dart';
import '../../providers/resume_form_provider.dart';
import '../../services/resume_repository.dart';
import '../../services/form_field_service.dart';
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
    return FutureBuilder<List<FormFieldDefinition>>(
      future: FormFieldService().getResumeFields(),
      initialData: FormFieldService.defaults,
      builder: (context, snapshot) {
        final fields = snapshot.data ?? FormFieldService.defaults;
        return ChangeNotifierProvider(
          create: (_) => ResumeFormProvider(repository, initial: existing),
          child: _WizardBody(
            isEditing: existing != null,
            initialStep: initialStep.clamp(0, _sections.length - 1).toInt(),
            fields: fields,
          ),
        );
      },
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
];

/// _WizardBody is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _WizardBody extends StatefulWidget {
  final bool isEditing;
  final int initialStep;
  final List<FormFieldDefinition> fields;

  const _WizardBody({
    required this.isEditing,
    required this.initialStep,
    required this.fields,
  });

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

  void _syncCustomFieldLabels(ResumeFormProvider form) {
    final labels = <String, String>{
      for (final field in widget.fields)
        if (!field.builtIn && field.enabled) field.id: field.label,
    };
    if (labels.isNotEmpty) {
      form.syncCustomFieldLabels(labels);
    }
  }

  Future<void> _saveDraft(BuildContext context) async {
    final form = context.read<ResumeFormProvider>();
    _syncCustomFieldLabels(form);
    await form.save();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft saved')));
    }
  }

  Future<void> _next(BuildContext context) async {
    final form = context.read<ResumeFormProvider>();
    _syncCustomFieldLabels(form);

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
    FormFieldDefinition? required;
    for (final field in widget.fields) {
      if (field.enabled &&
          (( _step == 3 && field.id == 'skills') ||
              (_step == 6 && field.id == 'languages') ||
              (_step == 7 && field.id == 'interests'))) {
        required = field;
        break;
      }
    }

    if (required == null || !required.required) return true;

    final empty = switch (_step) {
      3 => resume.skills.isEmpty,
      6 => resume.languages.isEmpty,
      7 => resume.interests.isEmpty,
      _ => false,
    };

    if (empty) {
      _showSectionError('Please add at least one ${required.label.toLowerCase()}.');
      return false;
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

  FormFieldDefinition? _field(String id) {
    for (final field in widget.fields) {
      if (field.id == id) return field;
    }
    return null;
  }

  String? Function(String?) _validator(FormFieldDefinition field) {
    return (value) {
      final text = value?.trim() ?? '';
      if (field.required && text.isEmpty) {
        return '${field.label} is required';
      }
      if (text.isEmpty) return null;

      switch (field.fieldType) {
        case 'email':
          return RegExp(r'^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$').hasMatch(text)
              ? null
              : 'Please enter a valid email';
        case 'phone':
          return RegExp(r'^\\d{10}$').hasMatch(text)
              ? null
              : 'Phone number must be exactly 10 digits';
        case 'number':
          return double.tryParse(text) == null ? 'Enter a valid number' : null;
        case 'url':
          final uri = Uri.tryParse(text);
          return uri != null && (uri.hasScheme || text.startsWith('www.'))
              ? null
              : 'Please enter a valid URL';
      }
      return null;
    };
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
                            if (_step == 0 &&
                                _field('resume.title')?.enabled == true) ...[
                              Text(
                                _field('resume.title')!.label,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              LabeledField(
                                label: _field('resume.title')!.placeholder.isEmpty
                                    ? _field('resume.title')!.label
                                    : _field('resume.title')!.placeholder,
                                initialValue:
                                    context.read<ResumeFormProvider>().draft.title,
                                onChanged:
                                    context.read<ResumeFormProvider>().setTitle,
                                requiredField: _field('resume.title')!.required,
                                validator: _validator(_field('resume.title')!,),
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
                            _StepForm(step: _step, fields: widget.fields),
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
  final List<FormFieldDefinition> fields;

  const _StepForm({
    required this.step,
    required this.fields,
  });

  FormFieldDefinition? _field(String key) {
    for (final field in fields) {
      if (field.id == key && field.enabled) return field;
    }
    return null;
  }

  List<FormFieldDefinition> get _customFields => fields
      .where((field) => field.enabled && !field.builtIn)
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));

  String? Function(String?) _validator(FormFieldDefinition field) {
    return (value) {
      final text = value?.trim() ?? '';
      if (field.required && text.isEmpty) {
        return '${field.label} is required';
      }
      if (text.isEmpty) return null;

      switch (field.fieldType) {
        case 'email':
          return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
              ? null
              : 'Please enter a valid email';
        case 'phone':
          return RegExp(r'^\d{10}$').hasMatch(text)
              ? null
              : 'Phone number must be exactly 10 digits';
        case 'number':
          return double.tryParse(text) == null ? 'Enter a valid number' : null;
        case 'url':
          final uri = Uri.tryParse(text);
          return uri != null && (uri.hasScheme || text.startsWith('www.'))
              ? null
              : 'Please enter a valid URL';
      }
      return null;
    };
  }

  LabeledField _fieldWidget({
    required FormFieldDefinition field,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return LabeledField(
      label: field.label,
      initialValue: initialValue,
      requiredField: field.required,
      maxLines: field.multiline ? 3 : 1,
      keyboardType: switch (field.fieldType) {
        'email' => TextInputType.emailAddress,
        'phone' => TextInputType.phone,
        'number' => TextInputType.number,
        'url' => TextInputType.url,
        _ => field.multiline ? TextInputType.multiline : TextInputType.text,
      },
      validator: _validator(field),
      suggestionFieldId: field.id,
      onChanged: onChanged,
    );
  }

  List<Widget> _customFieldWidgets(BuildContext context) {
    final form = context.watch<ResumeFormProvider>();
    return [
      if (_customFields.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text(
          'Additional Information',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Extra fields configured by the administrator.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        for (final field in _customFields)
          _fieldWidget(
            field: field,
            initialValue: form.draft.customFields[field.id] ?? '',
            onChanged: (value) => form.setCustomField(field.id, value, label: field.label),
          ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ResumeFormProvider>();
    final draft = form.draft;

    switch (step) {
      case 0:
        final p = draft.personal;
        final visible = fields.where(
          (f) => f.enabled && f.builtIn && f.section == 'Personal Information',
        );
        return Column(
          children: [
            for (final field in visible)
              if (field.fieldKey == 'personal.fullName')
                _fieldWidget(
                  field: field,
                  initialValue: p.fullName,
                  onChanged: (v) =>
                      form.updatePersonal((pi) => pi.copyWith(fullName: v)),
                )
              else if (field.fieldKey == 'personal.jobRole')
                _fieldWidget(
                  field: field,
                  initialValue: p.jobRole,
                  onChanged: (v) =>
                      form.updatePersonal((pi) => pi.copyWith(jobRole: v)),
                )
              else if (field.fieldKey == 'personal.email')
                _fieldWidget(
                  field: field,
                  initialValue: p.email,
                  onChanged: (v) =>
                      form.updatePersonal((pi) => pi.copyWith(email: v)),
                )
              else if (field.fieldKey == 'personal.phone')
                _fieldWidget(
                  field: field,
                  initialValue: p.phone,
                  onChanged: (v) =>
                      form.updatePersonal((pi) => pi.copyWith(phone: v)),
                )
              else if (field.fieldKey == 'personal.location')
                _fieldWidget(
                  field: field,
                  initialValue: p.location,
                  onChanged: (v) =>
                      form.updatePersonal((pi) => pi.copyWith(location: v)),
                )
              else if (field.fieldKey == 'personal.website')
                _fieldWidget(
                  field: field,
                  initialValue: p.website,
                  onChanged: (v) =>
                      form.updatePersonal((pi) => pi.copyWith(website: v)),
                ),
          ],
        );

      case 1:
        final school = _field('education.school');
        final degree = _field('education.degree');
        final years = _field('education.years');
        return Column(
          children: [
            for (final e in draft.education)
              EntryCard(
                onRemove: () => form.removeEducation(e.id),
                children: [
                  if (school != null)
                    _fieldWidget(
                      field: school,
                      initialValue: e.school,
                      onChanged: (v) => form.updateEducation(
                        e.id,
                        (x) => x.copyWith(school: v),
                      ),
                    ),
                  if (degree != null)
                    _fieldWidget(
                      field: degree,
                      initialValue: e.degree,
                      onChanged: (v) => form.updateEducation(
                        e.id,
                        (x) => x.copyWith(degree: v),
                      ),
                    ),
                  if (years != null)
                    _fieldWidget(
                      field: years,
                      initialValue: e.years,
                      onChanged: (v) => form.updateEducation(
                        e.id,
                        (x) => x.copyWith(years: v),
                      ),
                    ),
                ],
              ),
            if (school != null || degree != null || years != null)
              AddEntryButton(
                label: 'Add Education',
                onPressed: form.addEducation,
              ),
          ],
        );

      case 2:
        final role = _field('experience.role');
        final company = _field('experience.company');
        final duration = _field('experience.duration');
        final description = _field('experience.description');
        return Column(
          children: [
            for (final e in draft.experience)
              EntryCard(
                onRemove: () => form.removeExperience(e.id),
                children: [
                  if (role != null)
                    _fieldWidget(
                      field: role,
                      initialValue: e.role,
                      onChanged: (v) => form.updateExperience(
                        e.id,
                        (x) => x.copyWith(role: v),
                      ),
                    ),
                  if (company != null)
                    _fieldWidget(
                      field: company,
                      initialValue: e.company,
                      onChanged: (v) => form.updateExperience(
                        e.id,
                        (x) => x.copyWith(company: v),
                      ),
                    ),
                  if (duration != null)
                    _fieldWidget(
                      field: duration,
                      initialValue: e.duration,
                      onChanged: (v) => form.updateExperience(
                        e.id,
                        (x) => x.copyWith(duration: v),
                      ),
                    ),
                  if (description != null)
                    _fieldWidget(
                      field: description,
                      initialValue: e.description,
                      onChanged: (v) => form.updateExperience(
                        e.id,
                        (x) => x.copyWith(description: v),
                      ),
                    ),
                ],
              ),
            if (role != null || company != null || duration != null || description != null)
              AddEntryButton(
                label: 'Add Experience',
                onPressed: form.addExperience,
              ),
          ],
        );

      case 3:
        final field = _field('skills');
        return field == null
            ? const SizedBox.shrink()
            : ChipEntryField(
                hint: '${field.label}: add an item and press +',
                suggestionFieldId: field.id,
                values: draft.skills,
                onAdd: form.addSkill,
                onRemoveAt: form.removeSkillAt,
              );

      case 4:
        final name = _field('projects.name');
        final description = _field('projects.description');
        final link = _field('projects.link');
        return Column(
          children: [
            for (final e in draft.projects)
              EntryCard(
                onRemove: () => form.removeProject(e.id),
                children: [
                  if (name != null)
                    _fieldWidget(
                      field: name,
                      initialValue: e.name,
                      onChanged: (v) => form.updateProject(
                        e.id,
                        (x) => x.copyWith(name: v),
                      ),
                    ),
                  if (description != null)
                    _fieldWidget(
                      field: description,
                      initialValue: e.description,
                      onChanged: (v) => form.updateProject(
                        e.id,
                        (x) => x.copyWith(description: v),
                      ),
                    ),
                  if (link != null)
                    _fieldWidget(
                      field: link,
                      initialValue: e.link,
                      onChanged: (v) => form.updateProject(
                        e.id,
                        (x) => x.copyWith(link: v),
                      ),
                    ),
                ],
              ),
            if (name != null || description != null || link != null)
              AddEntryButton(label: 'Add Project', onPressed: form.addProject),
          ],
        );

      case 5:
        final name = _field('certifications.name');
        final issuer = _field('certifications.issuer');
        final year = _field('certifications.year');
        return Column(
          children: [
            for (final e in draft.certifications)
              EntryCard(
                onRemove: () => form.removeCertification(e.id),
                children: [
                  if (name != null)
                    _fieldWidget(
                      field: name,
                      initialValue: e.name,
                      onChanged: (v) => form.updateCertification(
                        e.id,
                        (x) => x.copyWith(name: v),
                      ),
                    ),
                  if (issuer != null)
                    _fieldWidget(
                      field: issuer,
                      initialValue: e.issuer,
                      onChanged: (v) => form.updateCertification(
                        e.id,
                        (x) => x.copyWith(issuer: v),
                      ),
                    ),
                  if (year != null)
                    _fieldWidget(
                      field: year,
                      initialValue: e.year,
                      onChanged: (v) => form.updateCertification(
                        e.id,
                        (x) => x.copyWith(year: v),
                      ),
                    ),
                ],
              ),
            if (name != null || issuer != null || year != null)
              AddEntryButton(
                label: 'Add Certification',
                onPressed: form.addCertification,
              ),
          ],
        );

      case 6:
        final field = _field('languages');
        return field == null
            ? const SizedBox.shrink()
            : ChipEntryField(
                hint: '${field.label}: add an item and press +',
                suggestionFieldId: field.id,
                values: draft.languages,
                onAdd: form.addLanguage,
                onRemoveAt: form.removeLanguageAt,
              );

      case 7:
        final field = _field('interests');
        return field == null
            ? const SizedBox.shrink()
            : ChipEntryField(
                hint: '${field.label}: add an item and press +',
                suggestionFieldId: field.id,
                values: draft.interests,
                onAdd: form.addInterest,
                onRemoveAt: form.removeInterestAt,
              );

      case 8:
        final name = _field('references.name');
        final relation = _field('references.relation');
        final contact = _field('references.contact');
        return Column(
          children: [
            for (final e in draft.references)
              EntryCard(
                onRemove: () => form.removeReference(e.id),
                children: [
                  if (name != null)
                    _fieldWidget(
                      field: name,
                      initialValue: e.name,
                      onChanged: (v) => form.updateReference(
                        e.id,
                        (x) => x.copyWith(name: v),
                      ),
                    ),
                  if (relation != null)
                    _fieldWidget(
                      field: relation,
                      initialValue: e.relation,
                      onChanged: (v) => form.updateReference(
                        e.id,
                        (x) => x.copyWith(relation: v),
                      ),
                    ),
                  if (contact != null)
                    _fieldWidget(
                      field: contact,
                      initialValue: e.contact,
                      onChanged: (v) => form.updateReference(
                        e.id,
                        (x) => x.copyWith(contact: v),
                      ),
                    ),
                ],
              ),
            if (name != null || relation != null || contact != null)
              AddEntryButton(
                label: 'Add Reference',
                onPressed: form.addReference,
              ),
            ..._customFieldWidgets(context),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

