/// ---------------------------------------------------------------------------
/// ResUniq - user_profile_provider.dart
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

import '../models/user_profile.dart';
import '../services/user_repository.dart';

/// Keeps the signed-in user's profile (name, email, role) in sync with
/// [UserRepository] for the Home greeting and Profile screen.
/// [repository] is null while signed out.
class UserProfileProvider extends ChangeNotifier {
  UserProfileProvider(this._repository) {
    _subscription = _repository?.watchProfile().listen((profile) {
      _profile = profile;
      notifyListeners();
    });
  }

  final UserRepository? _repository;
  StreamSubscription<UserProfile?>? _subscription;
  UserProfile? _profile;

  UserProfile? get profile => _profile;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
