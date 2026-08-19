/// ---------------------------------------------------------------------------
/// ResUniq - personal_details_service.dart
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

import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_picture_service.dart';

/// PersonalDetailsService is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class PersonalDetailsService {
  PersonalDetailsService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users_personal_details').doc(uid);

  Future<Map<String, dynamic>?> getDetails(String uid) async {
    final snap = await _doc(uid).get();
    return snap.exists ? snap.data() : null;
  }

  Future<void> saveDetails({
    required String uid,
    required String name,
    required String email,
    required String phone,
    Uint8List? profileImageBytes,
    bool removeProfileImage = false,
  }) async {
    String? profileImageUrl;

    if (profileImageBytes != null) {
      profileImageUrl = ProfilePictureService.encode(profileImageBytes);
    } else if (removeProfileImage) {
      profileImageUrl = '';
    } else {
      final existing = await getDetails(uid);
      profileImageUrl = existing?['profileImageUrl']?.toString() ?? '';
    }

    final batch = _db.batch();

    batch.set(_doc(uid), {
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    await _updateAllUserResumes(
      uid: uid,
      imageUrl: profileImageUrl,
    );
  }
  Future<void> _updateAllUserResumes({
    required String uid,
    required String imageUrl,
  }) async {
    final snapshot = await _db
        .collection('resumes')
        .where('ownerId', isEqualTo: uid)
        .get();

    const limit = 450;
    for (var start = 0; start < snapshot.docs.length; start += limit) {
      final end = (start + limit > snapshot.docs.length)
          ? snapshot.docs.length
          : start + limit;

      final batch = _db.batch();
      for (final doc in snapshot.docs.sublist(start, end)) {
        batch.update(doc.reference, {'profileImageUrl': imageUrl});
      }
      await batch.commit();
    }
  }

}
