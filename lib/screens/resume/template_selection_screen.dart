/// ---------------------------------------------------------------------------
/// ResUniq - template_selection_screen.dart
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
import '../../models/resume_template.dart';
import '../../services/pdf_service.dart';
import '../../services/pdf_generator.dart';
import '../../services/template_service.dart';
import '../../services/resume_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_animations.dart';
import '../home/home_screen.dart';
import 'user_template_preview_screen.dart';

/// TemplateSelectionScreen is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class TemplateSelectionScreen extends StatefulWidget {
  final ResumeDocument resume;

  const TemplateSelectionScreen({super.key, required this.resume});

  @override
  State<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

/// _TemplateSelectionScreenState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _TemplateSelectionScreenState extends State<TemplateSelectionScreen> {
  final TemplateService _templateService = TemplateService();
  String _selectedId = '';
  bool _busy = false;
  List<GeneratedResumeTemplate> _generatedTemplates = const [];

  @override
  void initState() {
    super.initState();
    // Only AI-generated template IDs are valid now. Old hard-coded template
    // IDs are intentionally ignored and must be replaced by a new selection.
    _selectedId = widget.resume.templateId.startsWith('ai_')
        ? widget.resume.templateId
        : '';
  }

  Future<void> _selectTemplate(String id) async {
    setState(() => _selectedId = id);
    final updated = widget.resume.copyWith(templateId: id);
    await context.read<ResumeRepository>().saveResume(updated);
  }

  Future<void> _downloadPdf() async {
    if (_selectedId.isEmpty) {
      _showMessage('Please choose an AI-powered template first.');
      return;
    }

    final exists = _generatedTemplates.any((t) => t.id == _selectedId);
    if (!exists) {
      _showMessage(
        'That template is no longer available. Please choose another template.',
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final resume = widget.resume.copyWith(templateId: _selectedId);
      PdfGenerator.registerGeneratedTemplates(_generatedTemplates);
      await PdfService.share(resume);
    } catch (e) {
      if (mounted) _showMessage('Could not generate PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _previewTemplate() async {
    if (_selectedId.isEmpty) {
      _showMessage('Please choose an AI-powered template first.');
      return;
    }

    final template = _generatedTemplates.cast<GeneratedResumeTemplate?>().firstWhere(
          (t) => t?.id == _selectedId,
          orElse: () => null,
        );

    if (template == null) {
      _showMessage(
        'That template is no longer available. Please choose another template.',
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserTemplatePreviewScreen(
          resume: widget.resume.copyWith(templateId: _selectedId),
          template: template,
        ),
      ),
    );
  }

  void _finish() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _generatedTile(GeneratedResumeTemplate template) {
    final isSelected = template.id == _selectedId;
    final hex = template.accentHex.replaceFirst('#', '');
    final accent = Color(int.parse('FF$hex', radix: 16));

    return FadeSlideIn(
      duration: const Duration(milliseconds: 360),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isSelected ? AppShadows.soft : const [],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => _selectTemplate(template.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryTintStrong
                            : AppColors.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            template.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        key: ValueKey(isSelected),
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
          onPressed: _finish,
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Text('Choose a Template'),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<GeneratedResumeTemplate>>(
          stream: _templateService.watchGeneratedTemplates(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child: Text('Could not load templates: ${snapshot.error}'),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            _generatedTemplates = snapshot.data ?? const [];
            PdfGenerator.registerGeneratedTemplates(_generatedTemplates);
            final generated = _generatedTemplates;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                8,
                AppSpacing.page,
                160,
              ),
              children: [
                Text(
                  'Choose one of the AI-powered templates created by the admin.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                if (generated.isEmpty)
                  const _EmptyTemplates()
                else
                  ...generated.map(_generatedTile),
              ],
            );
          },
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SecondaryPreviewButton(
                      busy: _busy || _selectedId.isEmpty,
                      onPressed: _previewTemplate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _busy || _selectedId.isEmpty ? null : _downloadPdf,
                      icon: const Icon(
                        Icons.file_download_outlined,
                        size: 20,
                      ),
                      label: const Text('Download PDF'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _finish,
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// _EmptyTemplates is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _EmptyTemplates extends StatelessWidget {
  const _EmptyTemplates();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 34),
          const SizedBox(height: 12),
          Text(
            'No templates available yet',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Ask the admin to add a template using the AI-powered builder.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// SecondaryPreviewButton is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class SecondaryPreviewButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onPressed;

  const SecondaryPreviewButton({
    super.key,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: const Icon(Icons.remove_red_eye_outlined, size: 20),
      label: const Text('Preview'),
    );
  }
}
