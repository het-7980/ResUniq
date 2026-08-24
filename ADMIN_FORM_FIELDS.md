# Admin Form Field Management

ResUniq now includes **Admin > Manage Form Fields**.

## What the administrator can control

For the Resume Create/Edit form, an admin can:

- edit labels of built-in fields;
- change placeholder/hint text;
- mark fields required or optional;
- enable/disable built-in fields;
- change supported validation/input type;
- add custom text/long-text fields;
- delete custom fields.

Built-in fields are soft-disabled rather than physically deleted so old resume
data remains safe.

## Data storage

Field definitions are stored in:

`form_fields/{fieldId}`

Administrator-created values are stored in each resume as:

`customFields`

and the current labels are stored as:

`customFieldLabels`.

## First-time setup

1. Publish the Firestore rules described in `FIRESTORE_FORM_FIELDS_RULES.md`.
2. Open the admin dashboard.
3. Open **Manage Form Fields**.
4. Press **Restore / Seed Default Fields**.
5. Edit or add fields as required.

The user form has a Dart fallback configuration, so existing users continue to
see the normal fields even before the Firestore collection is seeded.

## Important behavior

Disabling/removing a field only removes it from the user form. It does **not**
delete values already stored in existing resumes. This prevents an admin UI
change from silently destroying user data.
