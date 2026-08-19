/// ---------------------------------------------------------------------------
/// ResUniq - pdf_service.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Application services and repositories. These classes contain Firebase, Gemini, PDF, authentication, profile, and data-access logic so screens can stay focused on UI.
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

import 'package:printing/printing.dart';

import '../models/resume_document.dart';
import 'pdf_generator.dart';
import 'template_service.dart';

/// Thin wrapper around the `printing` package so screens don't need to
/// know about platform differences: on mobile/desktop this saves +
/// shares the file via the OS share sheet, on web it triggers a normal
/// browser download. Same API everywhere.
class PdfService {
  static Future<Uint8List> buildBytes(ResumeDocument resume) async {
    if (resume.templateId.startsWith('ai_')) {
      final template = await TemplateService().getGeneratedTemplate(resume.templateId);
      if (template != null) {
        PdfGenerator.registerGeneratedTemplates([template]);
      }
    }
    final bytes = await PdfGenerator.generate(resume);
    return Uint8List.fromList(bytes);
  }

  static String _fileName(ResumeDocument resume) {
    final safeTitle =
        resume.title.trim().isEmpty ? 'resume' : resume.title.trim();
    final cleaned = safeTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '');
    return '${cleaned.replaceAll(' ', '_')}.pdf';
  }

  /// Opens the native print/export preview sheet, letting the user save,
  /// print, or share the generated PDF.
  static Future<void> previewAndDownload(ResumeDocument resume) async {
    final bytes = await buildBytes(resume);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: _fileName(resume),
    );
  }

  /// Directly opens the OS share sheet (or browser download on web)
  /// with the generated PDF -- used by the "Download PDF" action.
  static Future<void> share(ResumeDocument resume) async {
    final bytes = await buildBytes(resume);
    await Printing.sharePdf(bytes: bytes, filename: _fileName(resume));
  }
}
