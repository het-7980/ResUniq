# Form Fields - Firestore Rules

The new admin form-field manager stores configuration in:

`form_fields/{fieldId}`

Add the following rules to your existing Firestore rules. Merge them into
your current rules instead of replacing your whole rules file.

```text
match /form_fields/{fieldId} {
  // Signed-in users need to read the active form configuration.
  allow read: if request.auth != null;

  // Only users whose users/{uid} document has role == "admin" can change
  // form configuration.
  allow create, update, delete: if request.auth != null
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin";
}
```

## Important

Keep your existing rules for `users`, `resumes`, and other collections.

After changing the rules, publish/deploy them in Firebase before testing the
new Manage Form Fields screen.

The app also has a built-in fallback configuration, so the Resume form still
works before the `form_fields` collection has been seeded. The first admin can
open **Manage Form Fields** and choose **Restore / Seed Default Fields**.
