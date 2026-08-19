# ResUniq Code Handover Guide

## What this project is

ResUniq is a Flutter resume-builder application. The project is split into
small layers so a beginner can find the right place to change something.

## Folder guide

```text
lib/
├── main.dart                         App startup and dependency injection
├── firebase_options.dart             Firebase platform configuration
├── models/                            Data structures
├── providers/                         App/UI state
├── services/                          Firebase, Gemini, PDF and data logic
├── screens/
│   ├── auth/                          Login, signup and authentication
│   ├── home/                          User home
│   ├── profile/                       Profile pages
│   ├── resume/                        Create/edit/template/preview flows
│   └── admin/                         Admin-only management pages
├── widgets/                           Reusable UI components
└── theme/                             Colors, typography and common styling
```

## How the main layers work

### 1. Models

Models are plain Dart classes such as `ResumeDocument`, `ResumeTemplate`, and
`UserProfile`.

They describe **what data looks like**. A model normally should not contain
Flutter UI code.

Example flow:

```text
Firebase data
    ↓
Model
    ↓
Provider / Repository
    ↓
Screen
```

### 2. Services and repositories

Services perform work that should not be mixed into widgets.

Examples in this project include:

- Firebase authentication
- Firestore resume/profile operations
- Gemini API calls
- PDF generation
- Google authentication
- Profile-picture handling
- Account deletion

If a beginner asks, "Where does this data come from?", check the relevant
repository/service first.

### 3. Providers

Providers hold state that screens need to react to.

For example, a provider can:

1. Ask a repository for resumes.
2. Store the result.
3. Notify the screen.
4. The screen rebuilds with the new data.

This keeps large amounts of state-management code out of the UI.

### 4. Screens

Screens are responsible mainly for:

- displaying the UI
- reading user input
- validating forms
- calling providers/services
- navigating to another screen

Avoid putting large Firebase/API implementations directly into a screen.

### 5. Widgets

Widgets are reusable pieces of UI. If the same UI appears in multiple
screens, it is a good candidate for `lib/widgets/`.

### 6. Theme

Common colors, text styles, shadows, spacing and other design values live in
`lib/theme/app_theme.dart`.

Prefer using the existing theme values instead of creating unrelated colors
or styles in individual screens.

## Common feature flows

### Create a resume

```text
Create Resume screen
        ↓
Resume form provider
        ↓
Resume repository
        ↓
Firebase / local storage
```

Template selection and PDF preview use the selected resume/template data.

### Edit a resume

The edit flow reuses the resume form architecture so validation and form
behavior remain consistent with creation.

### Template preview

The preview screen renders the selected template with resume data. It is
separate from the final PDF download/printing action so previewing does not
unexpectedly open a system print dialog.

### Admin

Admin screens are under `lib/screens/admin/`.

The administrator role is stored with the user's Firebase Authentication UID
in the Firestore `users` collection. The separate `create-admin` Node utility
can create the correct `users/{uid}` document.

## Where should I make a change?

| If you want to change... | Start here |
|---|---|
| App startup | `lib/main.dart` |
| Login/signup | `lib/screens/auth/` and authentication services |
| User profile | `lib/screens/profile/` |
| Resume form | `lib/screens/resume/create_resume_screen.dart` |
| Edit resume | `lib/screens/resume/edit_resume_screen.dart` |
| Resume template selection | `lib/screens/resume/template_selection_screen.dart` |
| User preview | `lib/screens/resume/user_template_preview_screen.dart` |
| PDF output | `lib/services/pdf_generator.dart` / `pdf_service.dart` |
| Gemini behavior | `lib/services/gemini_service.dart` |
| Firebase resume storage | `lib/services/firebase_resume_repository.dart` |
| Admin users | `lib/screens/admin/admin_users_screen.dart` |
| Admin resumes | `lib/screens/admin/admin_resumes_screen.dart` |
| Admin templates | `lib/screens/admin/admin_templates_screen.dart` |
| Admin preview | `lib/screens/admin/` preview screens |
| Common form fields | `lib/widgets/form_field_group.dart` |
| Common buttons | `lib/widgets/app_buttons.dart` |
| Animations | `lib/widgets/app_animations.dart` |
| Colors/theme | `lib/theme/app_theme.dart` |

## Beginner rules for future changes

1. Read the file header and class documentation before editing.
2. Search for an existing reusable widget before creating a new one.
3. Keep Firebase/API code in services or repositories.
4. Keep UI code in screens/widgets.
5. Reuse existing models instead of passing large unstructured maps when
   possible.
6. Run `flutter analyze` after changes.
7. Test both create and edit resume flows after changing shared form code.
8. Test both user and admin preview flows after changing PDF generation.
9. Do not put Firebase service-account credentials in the Flutter project.
10. Never commit `serviceAccountKey.json`.

## Recommended verification commands

```cmd
flutter clean
flutter pub get
flutter analyze
flutter build apk --release
```

For a feature change, test the smallest relevant flow first, then run the
full release build before handing the project to another team member.
