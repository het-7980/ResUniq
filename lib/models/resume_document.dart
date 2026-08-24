/// ---------------------------------------------------------------------------
/// ResUniq - resume_document.dart
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

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// PersonalInfo is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class PersonalInfo {
  final String fullName;
  final String jobRole;
  final String email;
  final String phone;
  final String location;
  final String website;
  final String profileImageUrl;

  const PersonalInfo({
    this.fullName = '',
    this.jobRole = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.website = '',
    this.profileImageUrl = '',
  });

  PersonalInfo copyWith({
    String? fullName,
    String? jobRole,
    String? email,
    String? phone,
    String? location,
    String? website,
    String? profileImageUrl,
  }) {
    return PersonalInfo(
      fullName: fullName ?? this.fullName,
      jobRole: jobRole ?? this.jobRole,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      website: website ?? this.website,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'jobRole': jobRole,
        'email': email,
        'phone': phone,
        'location': location,
        'website': website,
        'profileImageUrl': profileImageUrl,
      };

  factory PersonalInfo.fromMap(Map<String, dynamic> map) => PersonalInfo(
        fullName: map['fullName'] ?? '',
        jobRole: map['jobRole'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        location: map['location'] ?? '',
        website: map['website'] ?? '',
        profileImageUrl: map['profileImageUrl'] ?? '',
      );

  bool get isEmpty =>
      fullName.isEmpty &&
      jobRole.isEmpty &&
      email.isEmpty &&
      phone.isEmpty &&
      location.isEmpty;
}

/// EducationEntry is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class EducationEntry {
  final String id;
  final String school;
  final String degree;
  final String years;

  EducationEntry({
    String? id,
    this.school = '',
    this.degree = '',
    this.years = '',
  }) : id = id ?? _uuid.v4();

  EducationEntry copyWith({String? school, String? degree, String? years}) =>
      EducationEntry(
        id: id,
        school: school ?? this.school,
        degree: degree ?? this.degree,
        years: years ?? this.years,
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'school': school, 'degree': degree, 'years': years};

  factory EducationEntry.fromMap(Map<String, dynamic> map) => EducationEntry(
        id: map['id'],
        school: map['school'] ?? '',
        degree: map['degree'] ?? '',
        years: map['years'] ?? '',
      );
}

/// ExperienceEntry is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class ExperienceEntry {
  final String id;
  final String role;
  final String company;
  final String duration;
  final String description;

  ExperienceEntry({
    String? id,
    this.role = '',
    this.company = '',
    this.duration = '',
    this.description = '',
  }) : id = id ?? _uuid.v4();

  ExperienceEntry copyWith({
    String? role,
    String? company,
    String? duration,
    String? description,
  }) =>
      ExperienceEntry(
        id: id,
        role: role ?? this.role,
        company: company ?? this.company,
        duration: duration ?? this.duration,
        description: description ?? this.description,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role,
        'company': company,
        'duration': duration,
        'description': description,
      };

  factory ExperienceEntry.fromMap(Map<String, dynamic> map) => ExperienceEntry(
        id: map['id'],
        role: map['role'] ?? '',
        company: map['company'] ?? '',
        duration: map['duration'] ?? '',
        description: map['description'] ?? '',
      );
}

/// ProjectEntry is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class ProjectEntry {
  final String id;
  final String name;
  final String description;
  final String link;

  ProjectEntry({
    String? id,
    this.name = '',
    this.description = '',
    this.link = '',
  }) : id = id ?? _uuid.v4();

  ProjectEntry copyWith({String? name, String? description, String? link}) =>
      ProjectEntry(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        link: link ?? this.link,
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'description': description, 'link': link};

  factory ProjectEntry.fromMap(Map<String, dynamic> map) => ProjectEntry(
        id: map['id'],
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        link: map['link'] ?? '',
      );
}

/// CertificationEntry is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class CertificationEntry {
  final String id;
  final String name;
  final String issuer;
  final String year;

  CertificationEntry({
    String? id,
    this.name = '',
    this.issuer = '',
    this.year = '',
  }) : id = id ?? _uuid.v4();

  CertificationEntry copyWith({String? name, String? issuer, String? year}) =>
      CertificationEntry(
        id: id,
        name: name ?? this.name,
        issuer: issuer ?? this.issuer,
        year: year ?? this.year,
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'issuer': issuer, 'year': year};

  factory CertificationEntry.fromMap(Map<String, dynamic> map) =>
      CertificationEntry(
        id: map['id'],
        name: map['name'] ?? '',
        issuer: map['issuer'] ?? '',
        year: map['year'] ?? '',
      );
}

/// CustomFieldEntry represents a user-defined resume section.
///
/// The user can choose any title (for example, "Awards", "Publications",
/// "Volunteer Work", or "Achievements") and enter the content they want
/// displayed in that section. It is intentionally generic so users are not
/// limited to the predefined resume sections.
class CustomFieldEntry {
  final String id;
  final String label;
  final String value;

  CustomFieldEntry({
    String? id,
    this.label = '',
    this.value = '',
  }) : id = id ?? _uuid.v4();

  CustomFieldEntry copyWith({
    String? label,
    String? value,
  }) =>
      CustomFieldEntry(
        id: id,
        label: label ?? this.label,
        value: value ?? this.value,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'value': value,
      };

  factory CustomFieldEntry.fromMap(Map<String, dynamic> map) =>
      CustomFieldEntry(
        id: map['id'],
        label: map['label']?.toString() ?? '',
        value: map['value']?.toString() ?? '',
      );
}

/// ReferenceEntry is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class ReferenceEntry {
  final String id;
  final String name;
  final String relation;
  final String contact;

  ReferenceEntry({
    String? id,
    this.name = '',
    this.relation = '',
    this.contact = '',
  }) : id = id ?? _uuid.v4();

  ReferenceEntry copyWith({String? name, String? relation, String? contact}) =>
      ReferenceEntry(
        id: id,
        name: name ?? this.name,
        relation: relation ?? this.relation,
        contact: contact ?? this.contact,
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'relation': relation, 'contact': contact};

  factory ReferenceEntry.fromMap(Map<String, dynamic> map) => ReferenceEntry(
        id: map['id'],
        name: map['name'] ?? '',
        relation: map['relation'] ?? '',
        contact: map['contact'] ?? '',
      );
}

/// ---------------------------------------------------------------------
/// Root document.
///
/// Firestore structure:
/// resumes/{resumeId}
///   ownerId, title, templateId,
///   fullName, jobRole, email, phone, location, website,
///   objective, education, experience, skills, projects,
///   certifications, languages, interests, references,
///   createdAt, updatedAt
///
/// The Dart model keeps PersonalInfo grouped for the UI, but Firestore
/// stores those fields flat. fromMap also accepts the old nested
/// `personal` format so existing resumes are not lost.
/// ---------------------------------------------------------------------
class ResumeDocument {
  final String id;
  final String? ownerId;
  final String title;
  final String templateId;
  final PersonalInfo personal;
  final String objective;
  final List<EducationEntry> education;
  final List<ExperienceEntry> experience;
  final List<String> skills;
  final List<ProjectEntry> projects;
  final List<CertificationEntry> certifications;
  final List<String> languages;
  final List<String> interests;
  final List<ReferenceEntry> references;
  /// User-defined sections such as Awards, Publications, Volunteer Work, etc.
  final List<CustomFieldEntry> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;

  ResumeDocument({
    String? id,
    this.ownerId,
    this.title = 'Untitled Resume',
    this.templateId = '',
    this.personal = const PersonalInfo(),
    this.objective = '',
    List<EducationEntry>? education,
    List<ExperienceEntry>? experience,
    List<String>? skills,
    List<ProjectEntry>? projects,
    List<CertificationEntry>? certifications,
    List<String>? languages,
    List<String>? interests,
    List<ReferenceEntry>? references,
    List<CustomFieldEntry>? customFields,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        education = education ?? [],
        experience = experience ?? [],
        skills = skills ?? [],
        projects = projects ?? [],
        certifications = certifications ?? [],
        languages = languages ?? [],
        interests = interests ?? [],
        references = references ?? [],
        customFields = customFields ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get completion {
    final checks = <bool>[
      !personal.isEmpty,
      objective.isNotEmpty,
      education.isNotEmpty,
      experience.isNotEmpty,
      skills.isNotEmpty,
      projects.isNotEmpty,
      certifications.isNotEmpty,
      languages.isNotEmpty,
      interests.isNotEmpty,
      references.isNotEmpty,
      customFields.isNotEmpty,
    ];
    final done = checks.where((c) => c).length;
    return done / checks.length;
  }

  bool get isComplete => completion >= 0.99;

  // Compatibility aliases used by older widgets.
  double get progress => completion;
  String get templateName => templateId;

  ResumeDocument copyWith({
    String? title,
    String? templateId,
    PersonalInfo? personal,
    String? objective,
    List<EducationEntry>? education,
    List<ExperienceEntry>? experience,
    List<String>? skills,
    List<ProjectEntry>? projects,
    List<CertificationEntry>? certifications,
    List<String>? languages,
    List<String>? interests,
    List<ReferenceEntry>? references,
    List<CustomFieldEntry>? customFields,
    DateTime? updatedAt,
    String? ownerId,
  }) {
    return ResumeDocument(
      id: id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      templateId: templateId ?? this.templateId,
      personal: personal ?? this.personal,
      objective: objective ?? this.objective,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      projects: projects ?? this.projects,
      certifications: certifications ?? this.certifications,
      languages: languages ?? this.languages,
      interests: interests ?? this.interests,
      references: references ?? this.references,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'title': title,
        'templateId': templateId,
        'fullName': personal.fullName,
        'jobRole': personal.jobRole,
        'email': personal.email,
        'phone': personal.phone,
        'location': personal.location,
        'website': personal.website,
        'profileImageUrl': personal.profileImageUrl,
        'objective': objective,
        'education': education.map((e) => e.toMap()).toList(),
        'experience': experience.map((e) => e.toMap()).toList(),
        'skills': skills,
        'projects': projects.map((e) => e.toMap()).toList(),
        'certifications': certifications.map((e) => e.toMap()).toList(),
        'languages': languages,
        'interests': interests,
        'references': references.map((e) => e.toMap()).toList(),
        'customFields': customFields.map((e) => e.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ResumeDocument.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    List<T> listOf<T>(
      String key,
      T Function(Map<String, dynamic>) fromMap,
    ) {
      final raw = map[key];
      if (raw is! List) return <T>[];

      return raw
          .whereType<Map>()
          .map((item) => fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    DateTime date(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }

      // Avoid importing Firebase into the model. The repository converts
      // Firestore Timestamp values before calling this factory.
      return DateTime.now();
    }

    final legacyPersonal = map['personal'];
    final personalMap = legacyPersonal is Map
        ? Map<String, dynamic>.from(legacyPersonal)
        : <String, dynamic>{
            'fullName': map['fullName'] ?? '',
            'jobRole': map['jobRole'] ?? '',
            'email': map['email'] ?? '',
            'phone': map['phone'] ?? '',
            'location': map['location'] ?? '',
            'website': map['website'] ?? '',
            'profileImageUrl': map['profileImageUrl'] ?? '',
          };

    return ResumeDocument(
      id: documentId ?? map['id']?.toString(),
      ownerId: map['ownerId']?.toString(),
      title: map['title']?.toString() ?? 'Untitled Resume',
      templateId: map['templateId']?.toString() ?? '',
      personal: PersonalInfo.fromMap(personalMap),
      objective: map['objective']?.toString() ?? '',
      education: listOf('education', EducationEntry.fromMap),
      experience: listOf('experience', ExperienceEntry.fromMap),
      skills: List<String>.from(map['skills'] ?? const []),
      projects: listOf('projects', ProjectEntry.fromMap),
      certifications: listOf('certifications', CertificationEntry.fromMap),
      languages: List<String>.from(map['languages'] ?? const []),
      interests: List<String>.from(map['interests'] ?? const []),
      references: listOf('references', ReferenceEntry.fromMap),
      customFields: listOf('customFields', CustomFieldEntry.fromMap),
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
    );
  }
}
