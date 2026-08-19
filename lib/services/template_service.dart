/// ---------------------------------------------------------------------------
/// ResUniq - template_service.dart
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

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/resume_template.dart';

/// TemplateService is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class TemplateService {
  TemplateService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<GeneratedResumeTemplate>> watchGeneratedTemplates() {
    return _db
        .collection('resume_templates')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GeneratedResumeTemplate.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> createGeneratedTemplate(GeneratedResumeTemplate template) {
    return _db.collection('resume_templates').doc(template.id).set(template.toMap());
  }

  Future<void> deleteGeneratedTemplate(String id) {
    return _db.collection('resume_templates').doc(id).delete();
  }

  Future<GeneratedResumeTemplate?> getGeneratedTemplate(String id) async {
    final doc = await _db.collection('resume_templates').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return GeneratedResumeTemplate.fromMap(doc.id, doc.data()!);
  }
}
