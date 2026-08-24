/// ---------------------------------------------------------------------------
/// ResUniq - resume_form_provider.dart
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

import 'package:flutter/foundation.dart';

import '../models/resume_document.dart';
import '../services/resume_repository.dart';

/// Drives the Create/Edit Resume wizard. Holds a single draft
/// [ResumeDocument] in memory, exposes mutators for every section, and
/// persists via [ResumeRepository] when the user saves or finishes.
class ResumeFormProvider extends ChangeNotifier {
  ResumeFormProvider(this._repository, {ResumeDocument? initial})
      : draft = initial ?? ResumeDocument();

  final ResumeRepository _repository;
  ResumeDocument draft;
  bool saving = false;

  void _update(ResumeDocument Function(ResumeDocument) updater) {
    draft = updater(draft);
    notifyListeners();
  }

  // ---- Title & template -------------------------------------------------

  void setTitle(String title) => _update((d) => d.copyWith(title: title));

  void setTemplate(String templateId) =>
      _update((d) => d.copyWith(templateId: templateId));

  // ---- Personal / objective ----------------------------------------------

  void updatePersonal(PersonalInfo Function(PersonalInfo) updater) =>
      _update((d) => d.copyWith(personal: updater(d.personal)));

  void setObjective(String value) =>
      _update((d) => d.copyWith(objective: value));

  /// Updates a value created by the administrator in the dynamic field manager.
  void setCustomField(String fieldId, String value, {String? label}) =>
      _update((d) {
        final values = Map<String, String>.from(d.customFields);
        final labels = Map<String, String>.from(d.customFieldLabels);
        values[fieldId] = value;
        if (label != null && label.trim().isNotEmpty) {
          labels[fieldId] = label.trim();
        }
        return d.copyWith(
          customFields: values,
          customFieldLabels: labels,
        );
      });

  /// Keeps saved custom-field labels synchronized with the current admin
  /// configuration, even when the user did not edit the field value.
  void syncCustomFieldLabels(Map<String, String> labels) => _update((d) {
        final merged = Map<String, String>.from(d.customFieldLabels)
          ..addAll(labels);
        return d.copyWith(customFieldLabels: merged);
      });

  // ---- Generic list section helpers --------------------------------------

  void addEducation() => _update(
      (d) => d.copyWith(education: [...d.education, EducationEntry()]));

  void updateEducation(String id, EducationEntry Function(EducationEntry) f) =>
      _update((d) => d.copyWith(
          education: d.education.map((e) => e.id == id ? f(e) : e).toList()));

  void removeEducation(String id) => _update((d) =>
      d.copyWith(education: d.education.where((e) => e.id != id).toList()));

  void addExperience() => _update(
      (d) => d.copyWith(experience: [...d.experience, ExperienceEntry()]));

  void updateExperience(
          String id, ExperienceEntry Function(ExperienceEntry) f) =>
      _update((d) => d.copyWith(
          experience:
              d.experience.map((e) => e.id == id ? f(e) : e).toList()));

  void removeExperience(String id) => _update((d) =>
      d.copyWith(experience: d.experience.where((e) => e.id != id).toList()));

  void addProject() =>
      _update((d) => d.copyWith(projects: [...d.projects, ProjectEntry()]));

  void updateProject(String id, ProjectEntry Function(ProjectEntry) f) =>
      _update((d) => d.copyWith(
          projects: d.projects.map((e) => e.id == id ? f(e) : e).toList()));

  void removeProject(String id) => _update((d) =>
      d.copyWith(projects: d.projects.where((e) => e.id != id).toList()));

  void addCertification() => _update((d) =>
      d.copyWith(certifications: [...d.certifications, CertificationEntry()]));

  void updateCertification(
          String id, CertificationEntry Function(CertificationEntry) f) =>
      _update((d) => d.copyWith(
          certifications:
              d.certifications.map((e) => e.id == id ? f(e) : e).toList()));

  void removeCertification(String id) => _update((d) => d.copyWith(
      certifications: d.certifications.where((e) => e.id != id).toList()));

  void addReference() => _update(
      (d) => d.copyWith(references: [...d.references, ReferenceEntry()]));

  void updateReference(String id, ReferenceEntry Function(ReferenceEntry) f) =>
      _update((d) => d.copyWith(
          references:
              d.references.map((e) => e.id == id ? f(e) : e).toList()));

  void removeReference(String id) => _update((d) =>
      d.copyWith(references: d.references.where((e) => e.id != id).toList()));

  // ---- Simple tag/chip sections (skills, languages, interests) ----------

  void addSkill(String value) {
    if (value.trim().isEmpty) return;
    _update((d) => d.copyWith(skills: [...d.skills, value.trim()]));
  }

  void removeSkillAt(int index) => _update((d) {
        final list = [...d.skills]..removeAt(index);
        return d.copyWith(skills: list);
      });

  void addLanguage(String value) {
    if (value.trim().isEmpty) return;
    _update((d) => d.copyWith(languages: [...d.languages, value.trim()]));
  }

  void removeLanguageAt(int index) => _update((d) {
        final list = [...d.languages]..removeAt(index);
        return d.copyWith(languages: list);
      });

  void addInterest(String value) {
    if (value.trim().isEmpty) return;
    _update((d) => d.copyWith(interests: [...d.interests, value.trim()]));
  }

  void removeInterestAt(int index) => _update((d) {
        final list = [...d.interests]..removeAt(index);
        return d.copyWith(interests: list);
      });

  // ---- Persistence --------------------------------------------------------

  Future<void> save() async {
    saving = true;
    notifyListeners();
    try {
      await _repository.saveResume(draft);
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
