/// ---------------------------------------------------------------------------
/// ResUniq - local_resume_repository.dart
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

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/resume_document.dart';
import 'resume_repository.dart';

/// Default, works-offline-out-of-the-box implementation.
///
/// Persists resumes as JSON in [SharedPreferences] and exposes them
/// through a broadcast stream so the UI updates immediately after any
/// write -- the same shape a Firestore `snapshots()` stream would have.
/// This is what [FirebaseResumeRepository] is designed to drop in for.
class LocalResumeRepository implements ResumeRepository {
  static const _storageKey = 'resume_builder.resumes.v1';

  final StreamController<List<ResumeDocument>> _controller =
      StreamController<List<ResumeDocument>>.broadcast();

  List<ResumeDocument> _cache = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _cache = decoded
          .map((e) => ResumeDocument.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    _loaded = true;
    _emit();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_cache.map((r) => r.toMap()).toList());
    await prefs.setString(_storageKey, raw);
  }

  void _emit() {
    final sorted = [..._cache]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _controller.add(sorted);
  }

  @override
  Stream<List<ResumeDocument>> watchResumes() {
    // Kick off the initial load (fire-and-forget); listeners receive the
    // cached/persisted data as soon as it's ready via _emit().
    _ensureLoaded();
    return _controller.stream;
  }

  @override
  Future<ResumeDocument?> getResume(String id) async {
    await _ensureLoaded();
    try {
      return _cache.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveResume(ResumeDocument resume) async {
    await _ensureLoaded();
    final index = _cache.indexWhere((r) => r.id == resume.id);
    if (index == -1) {
      _cache.add(resume);
    } else {
      _cache[index] = resume;
    }
    await _persist();
    _emit();
  }

  @override
  Future<void> deleteResume(String id) async {
    await _ensureLoaded();
    _cache.removeWhere((r) => r.id == id);
    await _persist();
    _emit();
  }

  @override
  Future<ResumeDocument> duplicateResume(ResumeDocument resume) async {
    await _ensureLoaded();
    final copy = ResumeDocument.fromMap(resume.toMap()).copyWith(
      title: '${resume.title} (Copy)',
    );
    // fromMap keeps the same id, so force a fresh one for the duplicate.
    final withNewId = ResumeDocument(
      ownerId: copy.ownerId,
      title: copy.title,
      templateId: copy.templateId,
      personal: copy.personal,
      objective: copy.objective,
      education: copy.education,
      experience: copy.experience,
      skills: copy.skills,
      projects: copy.projects,
      certifications: copy.certifications,
      languages: copy.languages,
      interests: copy.interests,
      references: copy.references,
    );
    _cache.add(withNewId);
    await _persist();
    _emit();
    return withNewId;
  }

  void dispose() => _controller.close();
}
