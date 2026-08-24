/// ---------------------------------------------------------------------------
/// ResUniq - admin_form_fields_screen.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Administrator screen for controlling the fields shown in the user Resume
/// Create/Edit form.
///
/// Admins can:
/// - rename built-in fields;
/// - change placeholder text;
/// - change required/optional state;
/// - enable/disable fields;
/// - change field type/order;
/// - add custom text or long-text fields;
/// - remove custom fields.
///
/// Built-in fields are soft-deleted (disabled) so existing resume data remains
/// compatible. Custom fields are stored under ResumeDocument.customFields.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';

import '../../models/form_field_definition.dart';
import '../../services/form_field_service.dart';
import '../../theme/app_theme.dart';

class AdminFormFieldsScreen extends StatefulWidget {
  const AdminFormFieldsScreen({super.key});

  @override
  State<AdminFormFieldsScreen> createState() => _AdminFormFieldsScreenState();
}

class _AdminFormFieldsScreenState extends State<AdminFormFieldsScreen> {
  final _service = FormFieldService();
  bool _busy = false;

  Future<void> _seedDefaults() async {
    setState(() => _busy = true);
    try {
      await _service.seedDefaults();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default resume fields are ready.')),
        );
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(FormFieldDefinition field) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(field.builtIn ? 'Disable field?' : 'Delete field?'),
        content: Text(
          field.builtIn
              ? '“${field.label}” will be hidden from users. Existing resume data is not deleted.'
              : '“${field.label}” will be removed from the form. Existing saved values are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(field.builtIn ? 'Disable' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.delete(field);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _toggle(FormFieldDefinition field, bool enabled) async {
    try {
      await _service.save(field.copyWith(enabled: enabled));
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _openEditor({FormFieldDefinition? field}) async {
    final id = field?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final result = await showDialog<FormFieldDefinition>(
      context: context,
      builder: (_) => _FieldEditorDialog(
        field: field ??
            FormFieldDefinition(
              id: id,
              section: 'Additional Information',
              fieldKey: 'custom.$id',
              label: 'New Field',
              builtIn: false,
              order: 100,
            ),
        isNew: field == null,
      ),
    );

    if (result == null) return;

    try {
      await _service.save(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              field == null
                  ? 'Field added to the resume form.'
                  : 'Field updated successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text('Unable to update form field: $error'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      appBar: AppBar(
        title: const Text('Manage Form Fields'),
        centerTitle: true,
        backgroundColor: AppColors.secondaryBackground,
        surfaceTintColor: AppColors.secondaryBackground,
        actions: [
          IconButton(
            tooltip: 'Restore default field configuration',
            onPressed: _busy ? null : _seedDefaults,
            icon: const Icon(Icons.restore_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Field'),
      ),
      body: StreamBuilder<List<FormFieldDefinition>>(
        stream: _service.watchResumeFields(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load form fields.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final fields = snapshot.data!;
          final grouped = <String, List<FormFieldDefinition>>{};
          for (final field in fields) {
            grouped.putIfAbsent(field.section, () => []).add(field);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              8,
              AppSpacing.page,
              110,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.primaryTintStrong),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These settings control the user Create Resume and Edit Resume forms. Changes affect new and existing forms without changing the Dart code.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              for (final entry in grouped.entries)
                _SectionCard(
                  title: entry.key,
                  fields: entry.value,
                  onEdit: (field) => _openEditor(field: field),
                  onDelete: _delete,
                  onToggle: _toggle,
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _seedDefaults,
                icon: const Icon(Icons.settings_backup_restore_rounded),
                label: const Text('Restore / Seed Default Fields'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.fields,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final String title;
  final List<FormFieldDefinition> fields;
  final ValueChanged<FormFieldDefinition> onEdit;
  final Future<void> Function(FormFieldDefinition) onDelete;
  final Future<void> Function(FormFieldDefinition, bool) onToggle;

  @override
  Widget build(BuildContext context) {
    final sorted = [...fields]
      ..sort((a, b) => a.order.compareTo(b.order));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${sorted.where((f) => f.enabled).length}/${sorted.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          for (final field in sorted)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: field.enabled
                    ? AppColors.primaryTint
                    : AppColors.secondaryBackground,
                child: Icon(
                  field.builtIn
                      ? Icons.input_rounded
                      : Icons.add_box_outlined,
                  size: 18,
                  color: field.enabled
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              title: Text(
                field.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: field.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  decoration:
                      field.enabled ? null : TextDecoration.lineThrough,
                ),
              ),
              subtitle: Text(
                '${field.fieldType} • ${field.required ? 'Required' : 'Optional'}${field.builtIn ? ' • Built-in' : ' • Custom'}',
              ),
              trailing: Wrap(
                spacing: 0,
                children: [
                  Switch(
                    value: field.enabled,
                    onChanged: (value) => onToggle(field, value),
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => onEdit(field),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: field.builtIn ? 'Disable' : 'Delete',
                    onPressed: () => onDelete(field),
                    icon: Icon(
                      field.builtIn
                          ? Icons.visibility_off_outlined
                          : Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldEditorDialog extends StatefulWidget {
  const _FieldEditorDialog({
    required this.field,
    required this.isNew,
  });

  final FormFieldDefinition field;
  final bool isNew;

  @override
  State<_FieldEditorDialog> createState() => _FieldEditorDialogState();
}

class _FieldEditorDialogState extends State<_FieldEditorDialog> {
  late final TextEditingController _label;
  late final TextEditingController _placeholder;
  late final String _type;
  late bool _required;
  late bool _enabled;
  late bool _multiline;

  static const _types = ['text', 'multiline', 'email', 'phone', 'number', 'url'];

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.field.label);
    _placeholder = TextEditingController(text: widget.field.placeholder);
    _type = widget.field.fieldType;
    if (!_types.contains(_type)) _type = 'text';
    _required = widget.field.required;
    _enabled = widget.field.enabled;
    _multiline = widget.field.multiline || _type == 'multiline';
  }

  @override
  void dispose() {
    _label.dispose();
    _placeholder.dispose();
    super.dispose();
  }

  void _save() {
    final label = _label.text.trim();
    final order = widget.field.order;

    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field label is required.')),
      );
      return;
    }

    Navigator.pop(
      context,
      widget.field.copyWith(
        label: label,
        placeholder: _placeholder.text.trim(),
        fieldType: _type == 'multiline' ? 'text' : _type,
        multiline: _multiline || _type == 'multiline',
        required: _required,
        enabled: _enabled,
        order: order,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isNew ? 'Add Form Field' : 'Edit Form Field'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _label,
                decoration: const InputDecoration(
                  labelText: 'Field label',
                  hintText: 'e.g. Awards',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _placeholder,
                decoration: const InputDecoration(
                  labelText: 'Placeholder / hint',
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Field type'),
                items: _types
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type == 'multiline'
                              ? 'Long text'
                              : type[0].toUpperCase() + type.substring(1),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _type = value;
                    if (value == 'multiline') _multiline = true;
                  });
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Required field'),
                value: _required,
                onChanged: (value) => setState(() => _required = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enabled'),
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Multi-line input'),
                value: _multiline,
                onChanged: (value) => setState(() => _multiline = value),
              ),
              if (!widget.isNew)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.field.builtIn
                        ? 'Built-in field: delete disables it so existing data stays safe.'
                        : 'Custom field key: ${widget.field.id}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.isNew ? 'Add Field' : 'Save Changes'),
        ),
      ],
    );
  }
}
