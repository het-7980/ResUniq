# ResUniq

An AI-powered resume builder built with Flutter, Firebase, and Gemini.

ResUniq helps users create, edit, preview, and download professional resumes with customizable templates and AI-assisted content generation. It also includes an admin dashboard for managing users, resumes, and templates.

## Features

### User Features

- Email and password authentication
- Google Sign-In
- User profile management
- Create and edit resumes
- Manage multiple resumes
- Job role selection
- AI-assisted resume content generation
- Multiple resume templates
- In-app resume preview
- PDF resume generation and download
- Form validation
- Responsive Flutter UI

### Admin Features

- Manage users
- Manage user resumes
- Manage resume templates
- Preview templates and resumes
- Access admin-only functionality via role checks in Firestore

### AI Features

Gemini is used to assist with:

- Professional objective generation
- Job-role-based content suggestions
- Resume and template-related text generation
- Content quality improvements

## Resume Generation Flow

```text
Resume Data
    +
Template Design
    -> PDF Generator
    -> Final Resume
```

## In-App Preview Flow

```text
Resume
  -> PDF Generation
  -> In-App Preview
  -> View Resume
  -> Download (optional)
```

## Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Google Sign-In
- Gemini API
- PDF generation utilities

## Project Structure

```text
ResUniq/
├── android/
├── ios/
├── lib/
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── services/
│   ├── theme/
│   └── widgets/
├── assets/
├── test/
├── CODE_DOCUMENTATION.md
├── pubspec.yaml
└── README.md
```

## Requirements

- Flutter SDK
- Android SDK (for Android builds)
- Firebase project
- Git
- Node.js and npm (only if using admin utility scripts)

## Setup

1. Clone the repository:

```bash
git clone https://github.com/het-7980/ResUniq.git
cd ResUniq
```

2. Install dependencies:

```bash
flutter pub get
```

3. Configure Firebase:

- Add `android/app/google-services.json`
- Enable Email/Password, Google Sign-In, and Firestore
- Add SHA-1 and SHA-256 fingerprints for Android

4. Configure Gemini key locally:

Create `dart_defines.json`:

```json
{
  "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY"
}
```

Run the app:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

## Build

Release APK:

```bash
flutter build apk --release --dart-define-from-file=dart_defines.json
```

Split APKs per ABI:

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines.json
```

## Security Notes

Never commit secrets. Keep these local:

- `serviceAccountKey.json`
- `dart_defines.json`
- `.env`
- `.env.*`

Also avoid committing generated artifacts and local IDE state.

## Development Checklist

Before pushing:

- Run `flutter analyze`
- Test core flows
- Ensure no credentials are committed

## Documentation

Detailed code-level documentation is available in `CODE_DOCUMENTATION.md`.

## License

This project is developed as an academic/final-year project.
