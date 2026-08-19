/// ---------------------------------------------------------------------------
/// ResUniq - admin_templates_screen.dart
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
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../services/pdf_generator.dart';
import 'admin_template_preview_screen.dart';

import '../../models/resume_template.dart';
import '../../services/gemini_service.dart';
import '../../services/template_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_animations.dart';

/// AdminTemplatesScreen is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class AdminTemplatesScreen extends StatefulWidget {
  const AdminTemplatesScreen({super.key});

  @override
  State<AdminTemplatesScreen> createState() => _AdminTemplatesScreenState();
}

/// _AdminTemplatesScreenState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _AdminTemplatesScreenState extends State<AdminTemplatesScreen> {
  final _templateService = TemplateService();
  final _gemini = GeminiService();
  bool _adding = false;

  Future<void> _addTemplate() async {
    if (!_gemini.isConfigured) {
      _showMessage('AI service configuration is missing. Start the app with ');
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _adding = true);
    try {
      final bytes = await image.readAsBytes();
      final mime = image.mimeType ?? _mimeType(image.name);
      final spec = await _gemini.analyzeTemplateImage(
        imageBytes: bytes,
        mimeType: mime,
      );

      final template = GeneratedResumeTemplate(
        id: 'ai_${const Uuid().v4()}',
        name:
            spec['name']?.toString().trim().isNotEmpty == true
                ? spec['name'].toString().trim()
                : 'AI Template',
        description:
            spec['description']?.toString().trim().isNotEmpty == true
                ? spec['description'].toString().trim()
                : 'AI-generated resume template.',
        accentHex: _safeHex(spec['accentHex']?.toString()),
        layout: _safeLayout(spec['layout']?.toString()),
        sectionOrder: _safeSections(spec['sectionOrder']),
        showProfileImage: spec['showProfileImage'] != false,
        backgroundHex: _safeHex(spec['backgroundHex']?.toString(), '#FFFFFF'),
        textHex: _safeHex(spec['textHex']?.toString(), '#111827'),
        mutedTextHex: _safeHex(spec['mutedTextHex']?.toString(), '#6B7280'),
        secondaryHex: _safeHex(spec['secondaryHex']?.toString(), '#E5E7EB'),
        headerBackgroundHex: _safeHex(
          spec['headerBackgroundHex']?.toString(),
          '#FFFFFF',
        ),
        headerTextHex: _safeHex(spec['headerTextHex']?.toString(), '#111827'),
        headerAlignment: _safeChoice(
          spec['headerAlignment']?.toString(),
          const {'left', 'center', 'right'},
          'center',
        ),
        headerStyle: _safeChoice(spec['headerStyle']?.toString(), const {
          'simple',
          'band',
          'accentBand',
          'split',
        }, 'simple'),
        sectionStyle: _safeChoice(spec['sectionStyle']?.toString(), const {
          'rule',
          'accentBar',
          'boxed',
          'plain',
        }, 'rule'),
        profileShape: _safeChoice(spec['profileShape']?.toString(), const {
          'circle',
          'square',
          'none',
        }, 'circle'),
        contactStyle: _safeChoice(spec['contactStyle']?.toString(), const {
          'inline',
          'stacked',
        }, 'inline'),
        columnLayout: _safeChoice(spec['columnLayout']?.toString(), const {
          'single',
          'twoColumn',
        }, 'single'),
        sidebarPercent: _safeDouble(spec['sidebarPercent'], 30, 20, 45),
        sidebarBackgroundHex: _safeHex(
          spec['sidebarBackgroundHex']?.toString(),
          '#F3F4F6',
        ),
        sidebarTextHex: _safeHex(spec['sidebarTextHex']?.toString(), '#111827'),
        sidebarSections: _safeSections(spec['sidebarSections']),
        fontScale: _safeDouble(spec['fontScale'], 1.0, 0.85, 1.2),
        sectionSpacing: _safeDouble(spec['sectionSpacing'], 12, 6, 24),
        lineSpacing: _safeDouble(spec['lineSpacing'], 1.3, 1.05, 1.7),
      );

      await _templateService.createGeneratedTemplate(template);
      if (mounted) {
        _showMessage('Template generated and added successfully.');
      }
    } catch (e) {
      if (mounted) _showMessage('Could not add template: $e');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _previewTemplate(GeneratedResumeTemplate template) {
    // Preview uses a throwaway resume with realistic sample data. Nothing is
    // saved to Firestore and the admin's own data is never used.
    PdfGenerator.registerGeneratedTemplates([template]);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminTemplatePreviewScreen(template: template),
      ),
    );
  }

  Future<void> _removeTemplate(GeneratedResumeTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove template?'),
            content: Text(
              'Remove "${template.name}" from the user template list?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      await _templateService.deleteGeneratedTemplate(template.id);
      if (mounted) _showMessage('Template removed.');
    } catch (e) {
      if (mounted) _showMessage('Could not remove template: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _mimeType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _safeChoice(String? value, Set<String> allowed, String fallback) =>
      allowed.contains(value) ? value! : fallback;

  double _safeDouble(dynamic value, double fallback, double min, double max) {
    final number =
        value is num
            ? value.toDouble()
            : double.tryParse(value?.toString() ?? '');
    if (number == null || !number.isFinite) return fallback;
    return number.clamp(min, max).toDouble();
  }

  String _safeHex(String? value, [String fallback = '#0F285D']) =>
      RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value ?? '')
          ? value!.toUpperCase()
          : fallback;

  String _safeLayout(String? value) =>
      const {'minimal', 'classic', 'modern', 'executive'}.contains(value)
          ? value!
          : 'minimal';

  List<String> _safeSections(dynamic value) {
    const allowed = {
      'objective',
      'experience',
      'education',
      'projects',
      'skills',
      'certifications',
      'languages',
      'interests',
      'references',
    };
    if (value is! List) {
      return const [
        'objective',
        'experience',
        'education',
        'projects',
        'skills',
      ];
    }
    final result =
        value.whereType<String>().where(allowed.contains).toSet().toList();
    return result.isEmpty
        ? const ['objective', 'experience', 'education', 'projects', 'skills']
        : result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        title: const Text('Manage Templates'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adding ? null : _addTemplate,
        icon:
            _adding
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.add_rounded),
        label: Text(_adding ? 'Generating...' : 'Add Template'),
      ),
      body: StreamBuilder<List<GeneratedResumeTemplate>>(
        stream: _templateService.watchGeneratedTemplates(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load templates: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: AppLoadingIndicator(label: 'Loading templates...'),
            );
          }

          final generated = snapshot.data ?? const <GeneratedResumeTemplate>[];

          return FadeSlideIn(
            duration: const Duration(milliseconds: 460),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                8,
                AppSpacing.page,
                120,
              ),
              children: [
                Text(
                  'AI-powered templates',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload a reference screenshot/photo. The AI-powered builder converts its visual design into a usable template for your resumes.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                if (generated.isEmpty)
                  const _EmptyTemplates()
                else
                  ...generated.map(
                    (template) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TemplateCard(
                        name: template.name,
                        description: template.description,
                        id: template.id,
                        icon: Icons.auto_awesome_rounded,
                        accent: _colorFromHex(template.accentHex),
                        onPreview: () => _previewTemplate(template),
                        onRemove: () => _removeTemplate(template),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _colorFromHex(String value) {
    final hex = value.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

/// _TemplateCard is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.name,
    required this.description,
    required this.id,
    required this.icon,
    required this.accent,
    required this.onPreview,
    required this.onRemove,
  });

  final String name;
  final String description;
  final String id;
  final IconData icon;
  final Color accent;
  final VoidCallback onPreview;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Template ID: $id',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Preview template',
              onPressed: onPreview,
              icon: const Icon(Icons.visibility_outlined),
            ),
            IconButton(
              tooltip: 'Remove template',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
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
            'No AI-powered templates yet',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Use Add Template to create the first one with the AI-powered builder.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
