/// ---------------------------------------------------------------------------
/// ResUniq - firestore_admin_repository.dart
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
import '../models/user_profile.dart';
import 'admin_repository.dart';

/// Firebase implementation for the admin dashboard.
///
/// Firestore security rules are the real access control. These streams
/// are only started after CheckAuth has confirmed role == "admin".
class FirestoreAdminRepository implements AdminRepository {
  FirestoreAdminRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<UserProfile>> watchAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
          .toList();

      users.sort((a, b) {
        final nameA = a.name.trim().toLowerCase();
        final nameB = b.name.trim().toLowerCase();
        return nameA.compareTo(nameB);
      });

      return users;
    });
  }

  @override
  Stream<List<ResumeDocument>> watchAllResumes() {
    return _db.collection('resumes').snapshots().map((snapshot) {
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
  Future<void> setUserRole(String uid, String role) {
    if (role != 'user' && role != 'admin') {
      throw ArgumentError('Invalid role: $role');
    }

    return _db.collection('users').doc(uid).update({'role': role});
  }

  @override
  Future<void> setUserDisabled(String uid, bool disabled) {
    return _db.collection('users').doc(uid).update({'disabled': disabled});
  }

  @override
  Future<void> deleteResume(String id) {
    return _db.collection('resumes').doc(id).delete();
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
