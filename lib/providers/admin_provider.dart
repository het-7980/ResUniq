/// ---------------------------------------------------------------------------
/// ResUniq - admin_provider.dart
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
import '../models/user_profile.dart';
import '../services/admin_repository.dart';

/// AdminProvider is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class AdminProvider extends ChangeNotifier {
  AdminProvider(this._repository) {
    _usersSub = _repository.watchAllUsers().listen(
      (users) {
        _users = users;
        _usersLoading = false;
        _usersError = null;
        notifyListeners();
      },
      onError: (Object error) {
        _usersLoading = false;
        _usersError = error.toString();
        notifyListeners();
      },
    );

    _resumesSub = _repository.watchAllResumes().listen(
      (resumes) {
        _resumes = resumes;
        _resumesLoading = false;
        _resumesError = null;
        notifyListeners();
      },
      onError: (Object error) {
        _resumesLoading = false;
        _resumesError = error.toString();
        notifyListeners();
      },
    );
  }

  final AdminRepository _repository;

  StreamSubscription<List<UserProfile>>? _usersSub;
  StreamSubscription<List<ResumeDocument>>? _resumesSub;

  List<UserProfile> _users = [];
  List<ResumeDocument> _resumes = [];
  bool _usersLoading = true;
  bool _resumesLoading = true;
  String? _usersError;
  String? _resumesError;

  List<UserProfile> get users => List.unmodifiable(_users);
  List<ResumeDocument> get resumes => List.unmodifiable(_resumes);

  bool get loading => _usersLoading || _resumesLoading;
  String? get usersError => _usersError;
  String? get resumesError => _resumesError;

  int get totalUsers => _users.length;
  int get totalAdmins => _users.where((u) => u.isAdmin).length;
  int get totalResumes => _resumes.length;
  int get completeResumes => _resumes.where((r) => r.isComplete).length;

  List<ResumeDocument> resumesFor(String uid) =>
      _resumes.where((r) => r.ownerId == uid).toList();

  Future<void> setRole(String uid, String role) =>
      _repository.setUserRole(uid, role);

  Future<void> setDisabled(String uid, bool disabled) =>
      _repository.setUserDisabled(uid, disabled);

  Future<void> deleteResume(String id) => _repository.deleteResume(id);


  @override
  void dispose() {
    _usersSub?.cancel();
    _resumesSub?.cancel();
    super.dispose();
  }
}
