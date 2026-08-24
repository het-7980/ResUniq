/// ---------------------------------------------------------------------------
/// ResUniq - pdf_generator.dart
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

import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/resume_document.dart';
import '../models/resume_template.dart';
import 'profile_picture_service.dart';

/// Reconstructs the visual design inferred from the admin's uploaded reference.
/// Gemini provides the design specification; this class applies that
/// specification to the actual resume content.
class PdfGenerator {
  static final Map<String, GeneratedResumeTemplate> _generatedTemplates = {};

  static void registerGeneratedTemplates(Iterable<GeneratedResumeTemplate> templates) {
    for (final template in templates) {
      _generatedTemplates[template.id] = template;
    }
  }

  static Future<Uint8List?> _loadProfileImage(String url) async {
    if (url.trim().isEmpty) return null;
    if (url.startsWith('data:image/')) return ProfilePictureService.decode(url);
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return Uint8List.fromList(response.bodyBytes);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<int>> generate(ResumeDocument resume) async {
    final profileImage = await _loadProfileImage(resume.personal.profileImageUrl);
    final template = _generatedTemplates[resume.templateId];
    if (template == null) {
      throw StateError('No AI-powered template is selected for this resume. Choose a template first.');
    }
    return _render(resume, profileImage, template);
  }

  static Future<List<int>> _render(
    ResumeDocument resume,
    Uint8List? profileImage,
    GeneratedResumeTemplate template,
  ) async {
    final doc = pw.Document();
    final accent = _pdfColor(template.accentHex);
    final background = _pdfColor(template.backgroundHex);
    final text = _pdfColor(template.textHex);
    final muted = _pdfColor(template.mutedTextHex);
    final secondary = _pdfColor(template.secondaryHex);
    final sidebarBackground = _pdfColor(template.sidebarBackgroundHex);
    final sidebarText = _pdfColor(template.sidebarTextHex);
    final headerText = _pdfColor(template.headerTextHex);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        theme: _theme(),
        build: (_) {
          if (template.columnLayout == 'twoColumn' && template.sidebarSections.isNotEmpty) {
            // Gemini describes the reference design, but it must never decide
            // which user-entered resume fields are included. Start with the
            // visual order inferred by Gemini, then append every supported
            // resume section that Gemini could not identify in the image.
            final completeOrder = _completeSectionOrder(template.sectionOrder);
            final sidebarSet = template.sidebarSections.toSet();
            final sidebarOrder = completeOrder.where(sidebarSet.contains).toList();
            final mainOrder = completeOrder.where((key) => !sidebarSet.contains(key)).toList();
            final sidebarWidth = PdfPageFormat.a4.width * template.sidebarPercent / 100;

            // A normal Row is not a spanning widget in the `pdf` package.
            // When one of its columns becomes taller than an A4 page, the
            // whole Row becomes an unbreakable widget and MultiPage throws:
            // "Widget won't fit into the page...". Use Partitions instead;
            // it is specifically designed to split columnar content across
            // multiple pages.
            return [
              pw.Partitions(
                children: [
                  pw.Partition(
                    width: sidebarWidth,
                    child: pw.Container(
                      color: sidebarBackground,
                      padding: const pw.EdgeInsets.fromLTRB(20, 28, 16, 28),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: _sections(
                          resume,
                          template,
                          sidebarOrder,
                          accent: accent,
                          text: sidebarText,
                          muted: sidebarText,
                          secondary: secondary,
                          compact: true,
                        ),
                      ),
                    ),
                  ),
                  pw.Partition(
                    child: pw.Container(
                      color: background,
                      padding: const pw.EdgeInsets.fromLTRB(26, 30, 30, 30),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _header(resume, profileImage, template, accent, headerText, muted),
                          pw.SizedBox(height: 14),
                          ..._sections(
                            resume,
                            template,
                            mainOrder,
                            accent: accent,
                            text: text,
                            muted: muted,
                            secondary: secondary,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ];
          }

          // Keep the single-column layout spanning as well. A plain
          // Container is inseparable in MultiPage, so a long resume could
          // otherwise fail when its content exceeds one A4 page.
          return [
            pw.Partitions(
              children: [
                pw.Partition(
                  child: pw.Container(
                    color: background,
                    padding: const pw.EdgeInsets.fromLTRB(38, 34, 38, 34),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _header(resume, profileImage, template, accent, headerText, muted),
                        pw.SizedBox(height: 15),
                        ..._sections(
                          resume,
                          template,
                          _completeSectionOrder(template.sectionOrder),
                          accent: accent,
                          text: text,
                          muted: muted,
                          secondary: secondary,
                          compact: template.layout == 'classic' || template.layout == 'modern',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(
    ResumeDocument resume,
    Uint8List? profileImage,
    GeneratedResumeTemplate template,
    PdfColor accent,
    PdfColor headerText,
    PdfColor muted,
  ) {
    final personal = resume.personal;
    final name = personal.fullName.trim().isEmpty ? resume.title : personal.fullName;
    final alignment = template.headerAlignment == 'left'
        ? pw.CrossAxisAlignment.start
        : template.headerAlignment == 'right'
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.center;
    final textAlign = template.headerAlignment == 'left'
        ? pw.TextAlign.left
        : template.headerAlignment == 'right'
            ? pw.TextAlign.right
            : pw.TextAlign.center;

    pw.Widget? imageWidget;
    if (profileImage != null && template.profileShape != 'none') {
      imageWidget = pw.Container(
        width: 72,
        height: 72,
        decoration: pw.BoxDecoration(
          shape: template.profileShape == 'circle' ? pw.BoxShape.circle : pw.BoxShape.rectangle,
          borderRadius: template.profileShape == 'square' ? pw.BorderRadius.circular(4) : null,
        ),
        child: pw.ClipRect(
          child: pw.Image(pw.MemoryImage(profileImage), fit: pw.BoxFit.cover),
        ),
      );
    }

    final content = pw.Column(
      crossAxisAlignment: alignment,
      children: [
        if (imageWidget != null) imageWidget,
        if (imageWidget != null) pw.SizedBox(height: 8),
        pw.Text(
          name.toUpperCase(),
          textAlign: textAlign,
          style: pw.TextStyle(
            fontSize: 23 * template.fontScale,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.7,
            color: headerText,
          ),
        ),
        pw.SizedBox(height: 2),
        if (personal.jobRole.trim().isNotEmpty)
          pw.Text(
            personal.jobRole.trim(),
            textAlign: textAlign,
            style: pw.TextStyle(
              fontSize: 11.5 * template.fontScale,
              color: headerText,
            ),
          )
        else if (resume.title.trim().isNotEmpty)
          pw.Text(
            resume.title.trim(),
            textAlign: textAlign,
            style: pw.TextStyle(
              fontSize: 11.5 * template.fontScale,
              color: headerText,
            ),
          ),
        pw.SizedBox(height: 7),
        if (template.contactStyle == 'stacked')
          pw.Column(
            crossAxisAlignment: alignment,
            children: _contactValues(personal)
                .map((value) => pw.Text(
                      value,
                      textAlign: textAlign,
                      style: pw.TextStyle(fontSize: 8.2 * template.fontScale, color: muted),
                    ))
                .toList(),
          )
        else
          pw.Text(
            _contactLine(personal),
            textAlign: textAlign,
            style: pw.TextStyle(fontSize: 8.2 * template.fontScale, color: muted),
          ),
      ],
    );

    if (template.headerStyle == 'band' || template.headerStyle == 'accentBand') {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(16),
        color: template.headerStyle == 'accentBand'
            ? accent
            : _pdfColor(template.headerBackgroundHex),
        child: content,
      );
    }

    if (template.headerStyle == 'split') {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (imageWidget != null) imageWidget,
          if (imageWidget != null) pw.SizedBox(width: 12),
          pw.Expanded(child: content),
        ],
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 7),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: accent, width: 1)),
      ),
      child: content,
    );
  }

  /// Returns Gemini's visual section order plus every section supported by
  /// the app. Gemini is allowed to describe placement, but it is never
  /// allowed to remove user-entered data simply because a reference image
  /// does not visibly contain that section.
  static List<String> _completeSectionOrder(List<String> visualOrder) {
    const supportedSections = <String>[
      'objective',
      'experience',
      'education',
      'projects',
      'skills',
      'certifications',
      'languages',
      'interests',
      'references',
      'customFields',
    ];

    final result = <String>[];
    for (final key in visualOrder) {
      if (supportedSections.contains(key) && !result.contains(key)) {
        result.add(key);
      }
    }
    for (final key in supportedSections) {
      if (!result.contains(key)) result.add(key);
    }
    return result;
  }

  static List<pw.Widget> _sections(
    ResumeDocument resume,
    GeneratedResumeTemplate template,
    List<String> order, {
    required PdfColor accent,
    required PdfColor text,
    required PdfColor muted,
    required PdfColor secondary,
    required bool compact,
  }) {
    final widgets = <pw.Widget>[];
    for (final key in order) {
      String? title;
      pw.Widget? body;
      switch (key) {
        case 'objective':
          if (resume.objective.trim().isNotEmpty) {
            title = 'Profile';
            body = _bodyText(resume.objective, text, template);
          }
          break;
        case 'experience':
          if (resume.experience.isNotEmpty) {
            title = 'Work Experience';
            body = pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: resume.experience.map((entry) => _experienceItem(entry, text, muted, template, compact)).toList(),
            );
          }
          break;
        case 'education':
          if (resume.education.isNotEmpty) {
            title = 'Education';
            body = pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: resume.education.map((entry) => _educationItem(entry, text, muted, template, compact)).toList(),
            );
          }
          break;
        case 'projects':
          if (resume.projects.isNotEmpty) {
            title = 'Projects';
            body = pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: resume.projects.map((entry) => _projectItem(entry, text, muted, template)).toList(),
            );
          }
          break;
        case 'skills':
          if (resume.skills.isNotEmpty) {
            title = 'Skills';
            body = _bulletGrid(resume.skills, text, template);
          }
          break;
        case 'certifications':
          if (resume.certifications.isNotEmpty) {
            title = 'Certifications';
            body = pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: resume.certifications
                  .map((c) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 5),
                        child: pw.Text(
                          '${c.name}${c.issuer.isNotEmpty ? ' - ${c.issuer}' : ''}${c.year.isNotEmpty ? ' (${c.year})' : ''}',
                          style: pw.TextStyle(fontSize: 9.5 * template.fontScale, color: text),
                        ),
                      ))
                  .toList(),
            );
          }
          break;
        case 'languages':
          if (resume.languages.isNotEmpty) {
            title = 'Languages';
            body = _bulletGrid(resume.languages, text, template);
          }
          break;
        case 'interests':
          if (resume.interests.isNotEmpty) {
            title = 'Interests';
            body = _bulletGrid(resume.interests, text, template);
          }
          break;
        case 'references':
          if (resume.references.isNotEmpty) {
            title = 'References';
            body = pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: resume.references
                  .map((r) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 5),
                        child: pw.Text(
                          '${r.name}${r.relation.isNotEmpty ? ' | ${r.relation}' : ''}${r.contact.isNotEmpty ? ' | ${r.contact}' : ''}',
                          style: pw.TextStyle(fontSize: 9.5 * template.fontScale, color: text),
                        ),
                      ))
                  .toList(),
            );
          }
          break;
        case 'customFields':
          if (resume.customFields.isNotEmpty) {
            // Render each user-defined field as its own resume section.
            // The field title is controlled by the user, while the template
            // still controls typography, spacing, and section styling.
            for (final field in resume.customFields) {
              final label = field.label.trim();
              final value = field.value.trim();
              if (label.isEmpty || value.isEmpty) continue;
              widgets.add(_sectionTitle(label, template, accent, secondary));
              widgets.add(_bodyText(value, text, template));
              widgets.add(pw.SizedBox(height: template.sectionSpacing));
            }
          }
          break;
      }
      if (title == null || body == null) continue;
      widgets.add(_sectionTitle(title, template, accent, secondary));
      widgets.add(body);
      widgets.add(pw.SizedBox(height: template.sectionSpacing));
    }
    return widgets;
  }

  static pw.Widget _sectionTitle(String title, GeneratedResumeTemplate template, PdfColor accent, PdfColor secondary) {
    final titleWidget = pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 10.8 * template.fontScale,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 1.2,
        color: accent,
      ),
    );
    switch (template.sectionStyle) {
      case 'accentBar':
        return pw.Container(
          padding: const pw.EdgeInsets.only(left: 7, top: 3, bottom: 5),
          decoration: pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: accent, width: 3)),
          ),
          child: titleWidget,
        );
      case 'boxed':
        return pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: secondary)),
          child: titleWidget,
        );
      case 'plain':
        return pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: titleWidget);
      default:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [titleWidget, pw.SizedBox(height: 4), pw.Container(height: 0.6, color: secondary)],
          ),
        );
    }
  }

  static pw.Widget _bodyText(String value, PdfColor color, GeneratedResumeTemplate t) => pw.Text(
        value,
        style: pw.TextStyle(fontSize: 9.5 * t.fontScale, color: color, lineSpacing: t.lineSpacing),
      );

  static pw.Widget _educationItem(EducationEntry e, PdfColor text, PdfColor muted, GeneratedResumeTemplate t, bool compact) => pw.Padding(
        padding: pw.EdgeInsets.only(bottom: compact ? 5 : 7),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(e.school, style: pw.TextStyle(fontSize: 9 * t.fontScale, color: text)),
            pw.Row(
              children: [
                pw.Expanded(child: pw.Text(e.degree, style: pw.TextStyle(fontSize: 9.2 * t.fontScale, fontWeight: pw.FontWeight.bold, color: text))),
                if (e.years.isNotEmpty) pw.Text(e.years, style: pw.TextStyle(fontSize: 8.4 * t.fontScale, color: muted)),
              ],
            ),
          ],
        ),
      );

  static pw.Widget _experienceItem(ExperienceEntry e, PdfColor text, PdfColor muted, GeneratedResumeTemplate t, bool compact) => pw.Padding(
        padding: pw.EdgeInsets.only(bottom: compact ? 7 : 9),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: pw.Text(e.company, style: pw.TextStyle(fontSize: 8.9 * t.fontScale, color: text))),
                if (e.duration.isNotEmpty) pw.Text(e.duration, style: pw.TextStyle(fontSize: 8.3 * t.fontScale, color: muted)),
              ],
            ),
            pw.Text(e.role, style: pw.TextStyle(fontSize: 9.4 * t.fontScale, fontWeight: pw.FontWeight.bold, color: text)),
            if (e.description.isNotEmpty)
              pw.Padding(padding: const pw.EdgeInsets.only(top: 2), child: _bodyText(e.description, text, t)),
          ],
        ),
      );

  static pw.Widget _projectItem(ProjectEntry p, PdfColor text, PdfColor muted, GeneratedResumeTemplate t) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(p.name, style: pw.TextStyle(fontSize: 9.6 * t.fontScale, fontWeight: pw.FontWeight.bold, color: text)),
            if (p.description.isNotEmpty) _bodyText(p.description, text, t),
            if (p.link.isNotEmpty) pw.Text(p.link, style: pw.TextStyle(fontSize: 8.4 * t.fontScale, color: muted)),
          ],
        ),
      );

  static pw.Widget _bulletGrid(List<String> items, PdfColor text, GeneratedResumeTemplate t) {
    final rows = <pw.Widget>[];
    for (var i = 0; i < items.length; i += 3) {
      final cells = <pw.Widget>[];
      for (var c = 0; c < 3; c++) {
        final index = i + c;
        cells.add(
          pw.Expanded(
            child: index < items.length
                ? pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 8, bottom: 3),
                    child: pw.Text('-  ${items[index]}', style: pw.TextStyle(fontSize: 8.8 * t.fontScale, color: text)),
                  )
                : pw.SizedBox(),
          ),
        );
      }
      rows.add(pw.Row(children: cells));
    }
    return pw.Column(children: rows);
  }

  static pw.ThemeData _theme() => pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
        boldItalic: pw.Font.helveticaBoldOblique(),
      );

  static PdfColor _pdfColor(String hex) {
    final value = hex.replaceFirst('#', '');
    if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(value)) return PdfColors.black;
    return PdfColor.fromInt(int.parse(value, radix: 16) | 0xFF000000);
  }

  static List<String> _contactValues(PersonalInfo p) => [
        p.phone.trim(),
        p.email.trim(),
        p.location.trim(),
        p.website.trim(),
      ].where((value) => value.isNotEmpty).toList();

  static String _contactLine(PersonalInfo p) => _contactValues(p).join('    -    ');
}
