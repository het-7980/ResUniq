/// ---------------------------------------------------------------------------
/// ResUniq - resume_list_provider.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Provider/ChangeNotifier classes that hold UI state and connect screens to repositories and services.
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

import 'package:flutter/foundation.dart';

import '../models/resume_document.dart';
import '../services/resume_repository.dart';

/// Keeps the live list of the user's resumes in sync with
/// [ResumeRepository] and exposes simple CRUD helpers to the UI
/// (Home screen list, resume cards, profile stats).
class ResumeListProvider extends ChangeNotifier {
  ResumeListProvider(this._repository) {
    _subscription = _repository.watchResumes().listen((data) {
      _resumes = data;
      _loading = false;
      notifyListeners();
    });
  }

  final ResumeRepository _repository;
  ResumeRepository get repository => _repository;
  StreamSubscription<List<ResumeDocument>>? _subscription;

  List<ResumeDocument> _resumes = [];
  bool _loading = true;

  List<ResumeDocument> get resumes => _resumes;
  bool get loading => _loading;
  bool get isEmpty => !_loading && _resumes.isEmpty;

  double get averageCompletion {
    if (_resumes.isEmpty) return 0;
    final total = _resumes.fold<double>(0, (sum, r) => sum + r.completion);
    return total / _resumes.length;
  }

  Future<void> delete(String id) => _repository.deleteResume(id);

  Future<void> duplicate(ResumeDocument resume) =>
      _repository.duplicateResume(resume);

  Future<void> save(ResumeDocument resume) => _repository.saveResume(resume);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
