/// ---------------------------------------------------------------------------
/// ResUniq - user_profile.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Plain Dart data models used to represent users, resumes, and resume templates.
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

/// Matches users/{uid}.
///
/// role: "user" | "admin"
/// disabled: soft account block controlled by an admin.
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool disabled;
  final String createdAt;

  const UserProfile({
    required this.uid,
    this.name = '',
    this.email = '',
    this.role = 'user',
    this.disabled = false,
    this.createdAt = '',
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'disabled': disabled,
        'createdAt': createdAt,
      };

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    final created = map['createdAt'];

    return UserProfile(
      uid: uid,
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'user',
      disabled: map['disabled'] == true,
      createdAt: created?.toString() ?? '',
    );
  }
}
