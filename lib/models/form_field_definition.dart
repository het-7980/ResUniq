/// ---------------------------------------------------------------------------
/// ResUniq - form_field_definition.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Defines the fields that administrators can configure for user-facing forms.
///
/// Each definition describes one field in the Resume form. Built-in fields
/// keep their existing data keys so changing a label or required flag does
/// not break old resumes. Custom fields use their definition id as the
/// storage key inside ResumeDocument.customFields.
/// ---------------------------------------------------------------------------
library;

class FormFieldDefinition {
  final String id;
  final String formId;
  final String section;
  final String fieldKey;
  final String label;
  final String placeholder;
  final String fieldType;
  final bool required;
  final bool enabled;
  final bool builtIn;
  final bool multiline;
  final int order;

  const FormFieldDefinition({
    required this.id,
    this.formId = 'resume',
    required this.section,
    required this.fieldKey,
    required this.label,
    this.placeholder = '',
    this.fieldType = 'text',
    this.required = false,
    this.enabled = true,
    this.builtIn = true,
    this.multiline = false,
    this.order = 0,
  });

  FormFieldDefinition copyWith({
    String? section,
    String? fieldKey,
    String? label,
    String? placeholder,
    String? fieldType,
    bool? required,
    bool? enabled,
    bool? builtIn,
    bool? multiline,
    int? order,
  }) {
    return FormFieldDefinition(
      id: id,
      formId: formId,
      section: section ?? this.section,
      fieldKey: fieldKey ?? this.fieldKey,
      label: label ?? this.label,
      placeholder: placeholder ?? this.placeholder,
      fieldType: fieldType ?? this.fieldType,
      required: required ?? this.required,
      enabled: enabled ?? this.enabled,
      builtIn: builtIn ?? this.builtIn,
      multiline: multiline ?? this.multiline,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() => {
        'formId': formId,
        'section': section,
        'fieldKey': fieldKey,
        'label': label,
        'placeholder': placeholder,
        'fieldType': fieldType,
        'required': required,
        'enabled': enabled,
        'builtIn': builtIn,
        'multiline': multiline,
        'order': order,
      };

  factory FormFieldDefinition.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return FormFieldDefinition(
      id: id,
      formId: map['formId']?.toString() ?? 'resume',
      section: map['section']?.toString() ?? 'Additional Information',
      fieldKey: map['fieldKey']?.toString() ?? id,
      label: map['label']?.toString() ?? 'Custom Field',
      placeholder: map['placeholder']?.toString() ?? '',
      fieldType: map['fieldType']?.toString() ?? 'text',
      required: map['required'] == true,
      enabled: map['enabled'] != false,
      builtIn: map['builtIn'] == true,
      multiline: map['multiline'] == true,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }
}
