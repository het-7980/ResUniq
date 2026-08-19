/// ---------------------------------------------------------------------------
/// ResUniq - resume_repository.dart
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

import '../models/resume_document.dart';

/// Storage-agnostic contract for reading/writing resumes.
///
/// Swap [LocalResumeRepository] (default, works offline out of the box)
/// for [FirebaseResumeRepository] once Firebase is wired up -- nothing
/// else in the app needs to change since every screen talks to this
/// interface via [ResumeListProvider] / [ResumeFormProvider].
abstract class ResumeRepository {
  /// Live stream of the current user's resumes, newest first.
  Stream<List<ResumeDocument>> watchResumes();

  Future<ResumeDocument?> getResume(String id);

  /// Creates or overwrites a resume (upsert by [ResumeDocument.id]).
  Future<void> saveResume(ResumeDocument resume);

  Future<void> deleteResume(String id);

  Future<ResumeDocument> duplicateResume(ResumeDocument resume);
}
