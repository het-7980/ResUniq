/// ---------------------------------------------------------------------------
/// ResUniq - form_field_service.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Reads and writes administrator-controlled form field configuration.
///
/// Firestore collection:
///   form_fields/{fieldId}
///
/// The user form uses [defaults] when configuration has not been created yet.
/// Once an administrator opens the Form Fields manager, the default definitions
/// can be seeded into Firestore and then edited normally.
/// ---------------------------------------------------------------------------
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/form_field_definition.dart';

class FormFieldService {
  FormFieldService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('form_fields');

  Stream<List<FormFieldDefinition>> watchResumeFields() {
    return _collection
        .where('formId', isEqualTo: 'resume')
        .snapshots()
        .map((snapshot) {
      final fields = snapshot.docs
          .map((doc) => FormFieldDefinition.fromMap(doc.id, doc.data()))
          .toList();
      fields.sort((a, b) => a.order.compareTo(b.order));
      return _mergeWithDefaults(fields);
    });
  }

  Future<List<FormFieldDefinition>> getResumeFields() async {
    final snapshot =
        await _collection.where('formId', isEqualTo: 'resume').get();
    final fields = snapshot.docs
        .map((doc) => FormFieldDefinition.fromMap(doc.id, doc.data()))
        .toList();
    fields.sort((a, b) => a.order.compareTo(b.order));
    return _mergeWithDefaults(fields);
  }

  Future<void> seedDefaults() async {
    final batch = _db.batch();
    for (final field in defaults) {
      final ref = _collection.doc(field.id);
      batch.set(ref, field.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> save(FormFieldDefinition field) async {
    await _collection.doc(field.id).set(field.toMap());
  }

  Future<void> delete(FormFieldDefinition field) async {
    if (field.builtIn) {
      // Built-in fields are never physically deleted. Disabling them creates
      // a persistent "tombstone" so the fallback defaults cannot bring them
      // back for users.
      await save(field.copyWith(enabled: false));
      return;
    }
    await _collection.doc(field.id).delete();
  }

  List<FormFieldDefinition> _mergeWithDefaults(
    List<FormFieldDefinition> remote,
  ) {
    if (remote.isEmpty) return List.unmodifiable(defaults);

    final byId = <String, FormFieldDefinition>{
      for (final field in defaults) field.id: field,
    };
    for (final field in remote) {
      byId[field.id] = field;
    }

    final result = byId.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return List.unmodifiable(result);
  }

  /// Default configuration mirrors the fields already present in
  /// CreateResumeScreen. Admins can change these values without changing
  /// the Dart source code.
  static const List<FormFieldDefinition> defaults = [
    FormFieldDefinition(
      id: 'resume.title',
      section: 'Resume',
      fieldKey: 'title',
      label: 'Resume Name',
      placeholder: 'e.g. Software Developer Resume',
      required: true,
      order: 0,
    ),
    FormFieldDefinition(
      id: 'personal.fullName',
      section: 'Personal Information',
      fieldKey: 'personal.fullName',
      label: 'Full Name',
      required: true,
      order: 10,
    ),
    FormFieldDefinition(
      id: 'personal.jobRole',
      section: 'Personal Information',
      fieldKey: 'personal.jobRole',
      label: 'Target Job Role',
      required: true,
      order: 11,
    ),
    FormFieldDefinition(
      id: 'personal.email',
      section: 'Personal Information',
      fieldKey: 'personal.email',
      label: 'Email',
      fieldType: 'email',
      required: true,
      order: 12,
    ),
    FormFieldDefinition(
      id: 'personal.phone',
      section: 'Personal Information',
      fieldKey: 'personal.phone',
      label: 'Phone',
      fieldType: 'phone',
      required: true,
      order: 13,
    ),
    FormFieldDefinition(
      id: 'personal.location',
      section: 'Personal Information',
      fieldKey: 'personal.location',
      label: 'Location',
      order: 14,
    ),
    FormFieldDefinition(
      id: 'personal.website',
      section: 'Personal Information',
      fieldKey: 'personal.website',
      label: 'Website / LinkedIn',
      fieldType: 'url',
      order: 15,
    ),
    FormFieldDefinition(
      id: 'education.school',
      section: 'Education',
      fieldKey: 'education.school',
      label: 'School / University',
      required: true,
      order: 20,
    ),
    FormFieldDefinition(
      id: 'education.degree',
      section: 'Education',
      fieldKey: 'education.degree',
      label: 'Degree',
      required: true,
      order: 21,
    ),
    FormFieldDefinition(
      id: 'education.years',
      section: 'Education',
      fieldKey: 'education.years',
      label: 'Years (e.g. 2020 - 2024)',
      required: true,
      order: 22,
    ),
    FormFieldDefinition(
      id: 'experience.role',
      section: 'Experience',
      fieldKey: 'experience.role',
      label: 'Job Title',
      required: true,
      order: 30,
    ),
    FormFieldDefinition(
      id: 'experience.company',
      section: 'Experience',
      fieldKey: 'experience.company',
      label: 'Company',
      required: true,
      order: 31,
    ),
    FormFieldDefinition(
      id: 'experience.duration',
      section: 'Experience',
      fieldKey: 'experience.duration',
      label: 'Duration (e.g. Jan 2022 - Present)',
      required: true,
      order: 32,
    ),
    FormFieldDefinition(
      id: 'experience.description',
      section: 'Experience',
      fieldKey: 'experience.description',
      label: 'Description / achievements',
      required: true,
      multiline: true,
      order: 33,
    ),
    FormFieldDefinition(
      id: 'skills',
      section: 'Skills',
      fieldKey: 'skills',
      label: 'Skills',
      required: true,
      order: 40,
    ),
    FormFieldDefinition(
      id: 'projects.name',
      section: 'Projects',
      fieldKey: 'projects.name',
      label: 'Project Name',
      required: true,
      order: 50,
    ),
    FormFieldDefinition(
      id: 'projects.description',
      section: 'Projects',
      fieldKey: 'projects.description',
      label: 'Description',
      required: true,
      multiline: true,
      order: 51,
    ),
    FormFieldDefinition(
      id: 'projects.link',
      section: 'Projects',
      fieldKey: 'projects.link',
      label: 'Link (optional)',
      fieldType: 'url',
      order: 52,
    ),
    FormFieldDefinition(
      id: 'certifications.name',
      section: 'Certifications',
      fieldKey: 'certifications.name',
      label: 'Certification Name',
      required: true,
      order: 60,
    ),
    FormFieldDefinition(
      id: 'certifications.issuer',
      section: 'Certifications',
      fieldKey: 'certifications.issuer',
      label: 'Issuer',
      required: true,
      order: 61,
    ),
    FormFieldDefinition(
      id: 'certifications.year',
      section: 'Certifications',
      fieldKey: 'certifications.year',
      label: 'Year',
      fieldType: 'number',
      required: true,
      order: 62,
    ),
    FormFieldDefinition(
      id: 'languages',
      section: 'Languages',
      fieldKey: 'languages',
      label: 'Languages',
      required: true,
      order: 70,
    ),
    FormFieldDefinition(
      id: 'interests',
      section: 'Interests',
      fieldKey: 'interests',
      label: 'Interests',
      required: true,
      order: 80,
    ),
    FormFieldDefinition(
      id: 'references.name',
      section: 'References',
      fieldKey: 'references.name',
      label: 'Name',
      required: true,
      order: 90,
    ),
    FormFieldDefinition(
      id: 'references.relation',
      section: 'References',
      fieldKey: 'references.relation',
      label: 'Relation (e.g. Manager at Acme)',
      required: true,
      order: 91,
    ),
    FormFieldDefinition(
      id: 'references.contact',
      section: 'References',
      fieldKey: 'references.contact',
      label: 'Contact (email or phone)',
      required: true,
      order: 92,
    ),
  ];
}
