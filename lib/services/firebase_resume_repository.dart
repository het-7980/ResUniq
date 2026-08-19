/// ---------------------------------------------------------------------------
/// ResUniq - firebase_resume_repository.dart
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

import '../models/resume_document.dart';
import 'resume_repository.dart';

/// FirebaseResumeRepository is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class FirebaseResumeRepository implements ResumeRepository {
  FirebaseResumeRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('resumes');

  @override
  Stream<List<ResumeDocument>> watchResumes() {
    return _collection
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final resumes = snapshot.docs
          .map(
            (doc) => ResumeDocument.fromMap(
              _fromFirestoreMap(doc.data()),
              documentId: doc.id,
            ),
          )
          .toList();

      resumes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return resumes;
    });
  }

  @override
  Future<ResumeDocument?> getResume(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;

    return ResumeDocument.fromMap(
      _fromFirestoreMap(doc.data()!),
      documentId: doc.id,
    );
  }

  @override
  Future<void> saveResume(ResumeDocument resume) async {
    final personalDoc = await _db
        .collection('users_personal_details')
        .doc(userId)
        .get();

    final profileImageUrl =
        personalDoc.data()?['profileImageUrl']?.toString() ?? '';

    final updatedPersonal = resume.personal.copyWith(
      profileImageUrl: profileImageUrl,
    );

    final withOwner = resume.copyWith(
      ownerId: userId,
      personal: updatedPersonal,
    );
    final data = withOwner.toMap();

    data['createdAt'] = Timestamp.fromDate(withOwner.createdAt);
    data['updatedAt'] = Timestamp.fromDate(withOwner.updatedAt);

    await _collection.doc(withOwner.id).set(data);
  }

  @override
  Future<void> deleteResume(String id) {
    return _collection.doc(id).delete();
  }

  @override
  Future<ResumeDocument> duplicateResume(ResumeDocument resume) async {
    final duplicate = ResumeDocument(
      ownerId: userId,
      title: '${resume.title} (Copy)',
      templateId: resume.templateId,
      personal: resume.personal,
      objective: resume.objective,
      education: resume.education,
      experience: resume.experience,
      skills: resume.skills,
      projects: resume.projects,
      certifications: resume.certifications,
      languages: resume.languages,
      interests: resume.interests,
      references: resume.references,
    );

    final data = duplicate.toMap();
    data['createdAt'] = Timestamp.fromDate(duplicate.createdAt);
    data['updatedAt'] = Timestamp.fromDate(duplicate.updatedAt);

    await _collection.doc(duplicate.id).set(data);
    return duplicate;
  }

  Map<String, dynamic> _fromFirestoreMap(Map<String, dynamic> data) {
    final copy = Map<String, dynamic>.from(data);

    final createdAt = copy['createdAt'];
    if (createdAt is Timestamp) {
      copy['createdAt'] = createdAt.toDate().toIso8601String();
    }

    final updatedAt = copy['updatedAt'];
    if (updatedAt is Timestamp) {
      copy['updatedAt'] = updatedAt.toDate().toIso8601String();
    }

    return copy;
  }
}
