/// ---------------------------------------------------------------------------
/// ResUniq - user_template_preview_screen.dart
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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/resume_document.dart';
import '../../models/resume_template.dart';
import '../../services/pdf_generator.dart';
import '../../theme/app_theme.dart';

/// Full-screen, view-only preview of the selected template using the user's
/// current resume data. Nothing is printed, shared, downloaded, or saved from
/// this screen.
class UserTemplatePreviewScreen extends StatefulWidget {
  const UserTemplatePreviewScreen({
    super.key,
    required this.resume,
    required this.template,
  });

  final ResumeDocument resume;
  final GeneratedResumeTemplate template;

  @override
  State<UserTemplatePreviewScreen> createState() =>
      _UserTemplatePreviewScreenState();
}

/// _UserTemplatePreviewScreenState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _UserTemplatePreviewScreenState
    extends State<UserTemplatePreviewScreen> {
  @override
  void initState() {
    super.initState();
    PdfGenerator.registerGeneratedTemplates([widget.template]);
  }

  Future<Uint8List> _buildPdf() async {
    final bytes = await PdfGenerator.generate(
      widget.resume.copyWith(templateId: widget.template.id),
    );
    return Uint8List.fromList(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.template.name),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
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
                    'Preview of your resume. Nothing is printed, shared, or saved.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (_) => _buildPdf(),
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
      ),
    );
  }
}
