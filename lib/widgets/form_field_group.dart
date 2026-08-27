/// ---------------------------------------------------------------------------
/// ResUniq - form_field_group.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Reusable UI widgets shared by multiple screens. Keeping these widgets here avoids duplicating UI code.
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

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/suggestion_service.dart';

/// A labeled text field used throughout the wizard forms.
///
/// When [suggestionFieldId] is configured in [SuggestionService], matching
/// values appear below the field. Flutter's Autocomplete widget provides
/// desktop/web keyboard navigation: Up/Down changes the highlighted option and
/// Enter selects it. Touch/click selection works on all platforms.
class LabeledField extends StatelessWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool requiredField;
  final String? Function(String?)? validator;
  final String? suggestionFieldId;

  const LabeledField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.requiredField = false,
    this.validator,
    this.suggestionFieldId,
  });

  @override
  Widget build(BuildContext context) {
    final suggestionId = suggestionFieldId;
    final canSuggest = suggestionId != null && maxLines == 1;

    if (!canSuggest) return _plainField();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: initialValue),
        optionsBuilder: (value) =>
            SuggestionService.suggestionsFor(suggestionId, value.text),
        onSelected: onChanged,
        fieldViewBuilder: (
          context,
          controller,
          focusNode,
          onFieldSubmitted,
        ) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: (value) => onChanged(value.trim()),
            onFieldSubmitted: (_) => onFieldSubmitted(),
            validator: _validate,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _decoration(),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Builder(
                        builder: (context) {
                          final highlighted =
                              AutocompleteHighlightedOption.of(context) == index;
                          return Container(
                            color: highlighted
                                ? AppColors.primaryTint
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 19,
                                  color: highlighted
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(option)),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _plainField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: initialValue,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: (value) => onChanged(value.trim()),
        validator: _validate,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: _decoration(),
      ),
    );
  }

  String? _validate(String? value) {
    final trimmed = value?.trim() ?? '';
    if (requiredField && trimmed.isEmpty) return 'Please enter $label';
    return validator?.call(trimmed);
  }

  InputDecoration _decoration() => InputDecoration(
        hintText: label,
        prefixIcon: const Icon(Icons.edit_outlined, size: 19),
      );
}

/// A removable card wrapping one repeatable entry (an education row, an
/// experience row, etc.) with a trailing delete button.
class EntryCard extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback onRemove;

  const EntryCard({super.key, required this.children, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textSecondary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// "Add" button used at the bottom of repeatable sections.
class AddEntryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const AddEntryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 19),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: AppColors.primaryTint,
        side: const BorderSide(color: AppColors.primaryTintStrong, width: 1),
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

/// Chip-entry input for skills / languages / interests: a text field
/// with a submit button that adds a chip, plus the current chips with
/// individual remove buttons.
class ChipEntryField extends StatefulWidget {
  final String hint;
  final List<String> values;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemoveAt;
  final String? suggestionFieldId;

  const ChipEntryField({
    super.key,
    required this.hint,
    required this.values,
    required this.onAdd,
    required this.onRemoveAt,
    this.suggestionFieldId,
  });

  @override
  State<ChipEntryField> createState() => _ChipEntryFieldState();
}

/// _ChipEntryFieldState is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class _ChipEntryFieldState extends State<ChipEntryField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onAdd(value);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: widget.suggestionFieldId == null
                  ? TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(hintText: widget.hint),
                      onSubmitted: (_) => _submit(),
                    )
                  : RawAutocomplete<String>(
                      textEditingController: _controller,
                      focusNode: _focusNode,
                      optionsBuilder: (value) => SuggestionService.suggestionsFor(
                        widget.suggestionFieldId!,
                        value.text,
                      ),
                      onSelected: (value) {
                        widget.onAdd(value);
                        _controller.clear();
                        _focusNode.requestFocus();
                      },
                      fieldViewBuilder: (
                        context,
                        controller,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(hintText: widget.hint),
                          onSubmitted: (_) => onFieldSubmitted(),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 240),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return InkWell(
                                    onTap: () => onSelected(option),
                                    child: Builder(
                                      builder: (context) {
                                        final highlighted =
                                            AutocompleteHighlightedOption.of(context) == index;
                                        return Container(
                                          color: highlighted
                                              ? AppColors.primaryTint
                                              : Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          child: Text(option),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 56,
              width: 56,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                child: const Icon(Icons.add_rounded),
              ),
            ),
          ],
        ),
        if (widget.values.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(widget.values.length, (i) {
              return Chip(
                label: Text(widget.values[i]),
                backgroundColor: AppColors.primaryTint,
                labelStyle: const TextStyle(color: AppColors.primary),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                deleteIconColor: AppColors.primary,
                onDeleted: () => widget.onRemoveAt(i),
                side: BorderSide.none,
              );
            }),
          ),
        ],
      ],
    );
  }
}
