/// ---------------------------------------------------------------------------
/// ResUniq - admin_template_preview_screen.dart
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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/resume_document.dart';
import '../../models/resume_template.dart';
import '../../services/pdf_generator.dart';
import '../../theme/app_theme.dart';

/// Full-screen preview of an AI-generated template using disposable sample
/// resume data. The sample data never gets stored in Firestore.
class AdminTemplatePreviewScreen extends StatefulWidget {
  const AdminTemplatePreviewScreen({super.key, required this.template});

  final GeneratedResumeTemplate template;

  @override
  State<AdminTemplatePreviewScreen> createState() =>
      _AdminTemplatePreviewScreenState();
}

/// _AdminTemplatePreviewScreenState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _AdminTemplatePreviewScreenState
    extends State<AdminTemplatePreviewScreen> {
  late ResumeDocument _sampleResume;

  @override
  void initState() {
    super.initState();
    PdfGenerator.registerGeneratedTemplates([widget.template]);
    _sampleResume = _buildSampleResume(widget.template.id);
  }

  ResumeDocument _buildSampleResume(String templateId) {
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    const firstNames = ['Aarav', 'Maya', 'Rohan', 'Anaya', 'Kabir', 'Isha'];
    const lastNames = ['Shah', 'Mehta', 'Patel', 'Kapoor', 'Joshi', 'Desai'];
    const roles = [
      'Flutter Developer',
      'Software Engineer',
      'UI/UX Designer',
      'Product Designer',
      'Full Stack Developer',
    ];

    final name =
        '${firstNames[random.nextInt(firstNames.length)]} '
        '${lastNames[random.nextInt(lastNames.length)]}';
    final role = roles[random.nextInt(roles.length)];

    return ResumeDocument(
      title: '$role Resume',
      templateId: templateId,
      personal: PersonalInfo(
        fullName: name,
        jobRole: role,
        email: 'alex.morgan@example.com',
        phone: '+91 98765 43210',
        location: 'Ahmedabad, India',
        website: 'linkedin.com/in/alexmorgan',
      ),
      objective:
          'Creative and detail-oriented professional with experience building '
          'user-focused digital products. Passionate about solving problems '
          'through clean design, thoughtful technology, and collaborative work.',
      education: [
        EducationEntry(
          school: 'Silver Oak University',
          degree: 'B.Tech in Computer Engineering',
          years: '2021 - 2025',
        ),
        EducationEntry(
          school: 'City Higher Secondary School',
          degree: 'Higher Secondary Education',
          years: '2019 - 2021',
        ),
      ],
      experience: [
        ExperienceEntry(
          role: role,
          company: 'Nova Digital Labs',
          duration: '2024 - Present',
          description:
              'Developed responsive mobile experiences, collaborated with '
              'designers and backend engineers, and improved application '
              'performance through reusable components and clean architecture.',
        ),
        ExperienceEntry(
          role: 'Software Engineering Intern',
          company: 'BrightWorks Technologies',
          duration: '2023 - 2024',
          description:
              'Built product features, fixed bugs, wrote documentation, and '
              'worked with a cross-functional team to deliver reliable releases.',
        ),
      ],
      skills: const [
        'Flutter',
        'Dart',
        'Firebase',
        'UI Design',
        'REST APIs',
        'Git',
        'Figma',
        'Problem Solving',
      ],
      projects: [
        ProjectEntry(
          name: 'Resume Builder',
          description:
              'Created a resume builder with customizable templates, '
              'Firebase storage, and automated PDF generation.',
          link: 'github.com/alexmorgan/resume-builder',
        ),
        ProjectEntry(
          name: 'TaskFlow Mobile App',
          description:
              'Designed and developed a productivity app with authentication, '
              'cloud synchronization, and an accessible mobile interface.',
          link: 'github.com/alexmorgan/taskflow',
        ),
      ],
      certifications: [
        CertificationEntry(
          name: 'Flutter Development',
          issuer: 'Google Developer Training',
          year: '2024',
        ),
        CertificationEntry(
          name: 'Firebase Fundamentals',
          issuer: 'Google Cloud Skills',
          year: '2024',
        ),
      ],
      languages: const ['English', 'Hindi', 'Gujarati'],
      interests: const [
        'Product Design',
        'Open Source',
        'Photography',
        'Technology',
      ],
      references: [
        ReferenceEntry(
          name: 'Priya Nair',
          relation: 'Engineering Manager',
          contact: 'priya.nair@example.com',
        ),
      ],
    );
  }

  void _refreshSample() {
    setState(() {
      _sampleResume = _buildSampleResume(widget.template.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.template.name),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Generate different sample data',
            onPressed: _refreshSample,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primaryTint,
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined, size: 19),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Preview with sample data. Nothing is saved to Firebase.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (format) async {
                final bytes = await PdfGenerator.generate(_sampleResume);
                return Uint8List.fromList(bytes);
              },
              pdfFileName:
                  '${widget.template.name.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')}_preview.pdf',
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
