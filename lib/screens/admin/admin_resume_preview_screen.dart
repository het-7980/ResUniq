/// ---------------------------------------------------------------------------
/// ResUniq - admin_resume_preview_screen.dart
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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/resume_document.dart';
import '../../models/resume_template.dart';
import '../../services/pdf_generator.dart';
import '../../services/template_service.dart';
import '../../theme/app_theme.dart';

/// Full-screen, view-only preview of an existing user's resume.
///
/// This is intentionally the same in-app PdfPreview experience used by the
/// user-side and admin template previews. It never opens the native print
/// dialog and does not print, share, download, or modify the resume.
class AdminResumePreviewScreen extends StatefulWidget {
  const AdminResumePreviewScreen({
    super.key,
    required this.resume,
  });

  final ResumeDocument resume;

  @override
  State<AdminResumePreviewScreen> createState() =>
      _AdminResumePreviewScreenState();
}

/// _AdminResumePreviewScreenState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _AdminResumePreviewScreenState extends State<AdminResumePreviewScreen> {
  late Future<GeneratedResumeTemplate?> _templateFuture;

  @override
  void initState() {
    super.initState();
    _templateFuture = _loadTemplate();
  }

  Future<GeneratedResumeTemplate?> _loadTemplate() async {
    final templateId = widget.resume.templateId.trim();
    if (templateId.isEmpty) return null;

    final template = await TemplateService().getGeneratedTemplate(templateId);
    if (template != null) {
      PdfGenerator.registerGeneratedTemplates([template]);
    }
    return template;
  }

  Future<Uint8List> _buildPdf(GeneratedResumeTemplate template) async {
    PdfGenerator.registerGeneratedTemplates([template]);
    final bytes = await PdfGenerator.generate(
      widget.resume.copyWith(templateId: template.id),
    );
    return Uint8List.fromList(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.resume.title.trim().isEmpty
              ? 'Resume Preview'
              : widget.resume.title,
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
      ),
      body: FutureBuilder<GeneratedResumeTemplate?>(
        future: _templateFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _PreviewError(
              message: 'Unable to load the resume template.\n${snapshot.error}',
              onRetry: () {
                setState(() {
                  _templateFuture = _loadTemplate();
                });
              },
            );
          }

          final template = snapshot.data;
          if (template == null) {
            return _PreviewError(
              message:
                  'The template used by this resume is no longer available.',
              onRetry: () {
                setState(() {
                  _templateFuture = _loadTemplate();
                });
              },
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: AppColors.primaryTint,
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 19),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Preview of ${widget.resume.personal.fullName.trim().isEmpty ? 'this resume' : widget.resume.personal.fullName}. Nothing is printed, shared, or saved.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PdfPreview(
                  build: (_) => _buildPdf(template),
                  pdfFileName:
                      '${widget.resume.title.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')}_preview.pdf',
                  allowPrinting: false,
                  allowSharing: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  maxPageWidth: 850,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// _PreviewError is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _PreviewError extends StatelessWidget {
  const _PreviewError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 52,
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Preview unavailable',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
