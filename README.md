# ResUniq

**ResUniq** is an AI-powered resume builder developed with Flutter, Firebase, and Gemini. It helps users create professional resumes, manage multiple resumes, generate resume content with AI assistance, preview resumes, and export them as PDF files.

The project also includes an admin dashboard for managing users, resumes, and resume templates.

---

## Features

### User Features

- Email and password authentication
- Google Sign-In
- User profile management
- Change password
- Delete account
- Create multiple resumes
- Edit and manage existing resumes
- Resume form validation
- Professional resume templates
- In-app resume preview
- PDF resume generation and download
- Responsive Flutter interface
- Mobile-friendly dialogs and validation messages

### Smart Autofill Suggestions

ResUniq provides contextual suggestions where they are useful instead of showing suggestions for every field.

Examples include:

- **Job Title / Role** — software engineer, data analyst, Flutter developer, and more
- **Degree** — B.Tech, B.E., BCA, MBA, Ph.D., etc.
- **Course / Major / Specialization** — Computer Science and Engineering (CSE), Information Technology, AI & ML, Data Science, Mechanical Engineering, and more
- **College / University** — suggestions from institutions in different countries
- **Location** — international city and location suggestions
- **Skills** — technical and soft skills
- **Languages**
- **Certifications**
- **Interests**

Suggestions are optional: users can still type and enter a value that is not in the suggestion list.

The autocomplete interface is designed to work on both desktop/web and Android. On Android, the suggestion list is positioned to remain visible above the on-screen keyboard.

### Education Information

Education entries support separate:

```text
Degree
Course / Major / Specialization
College / University
Years
```

Existing resume data without a Course field remains compatible with the updated data model.

---

## AI Features

Gemini is used to assist with resume-related content, including:

- Professional objective generation
- Job-role-based content assistance
- Resume text generation
- Content improvement
- Template-related text generation

AI-generated content should be reviewed by the user before being included in a final resume.

---

## Admin Features

The project includes an admin side for authorized administrators.

Admin functionality includes:

- Manage users
- Manage user resumes
- Manage resume templates
- Preview templates using sample/random data
- Preview resumes
- Access admin-only functionality through role-based access

### Admin Role

An authorized user's Firestore profile can contain an admin role such as:

```text
role: "admin"
```

The admin role should only be assigned by a trusted administrator or secure administrative process.

**Never add an option in the normal user application that allows users to promote themselves to admin.**

---

## Resume Generation Flow

```text
User enters resume information
            ↓
      Resume data model
            ↓
       Selected template
            ↓
       PDF generation
            ↓
       Final resume PDF
```

---

## In-App Preview Flow

```text
Resume data
    ↓
PDF generation
    ↓
In-app preview
    ↓
View resume
    ↓
Download / share as required
```

---

## Technology Stack

- **Flutter** — application framework
- **Dart** — programming language
- **Firebase Authentication** — user authentication
- **Cloud Firestore** — application and resume data
- **Google Sign-In** — Google authentication
- **Gemini API** — AI-assisted content generation
- **PDF generation utilities** — resume PDF creation
- **Node.js / npm** — administrative utility scripts where required

---

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

The exact folders and files may change as development continues.

---

## Requirements

Before running ResUniq, install:

- Flutter SDK
- Dart SDK (included with Flutter)
- Android SDK for Android development
- Android Studio or another Flutter-compatible IDE
- Git
- Node.js and npm if administrative utility scripts are used
- A Firebase project
- A Gemini API key for AI functionality

---

## Firebase Setup

1. Create or use a Firebase project.
2. Add the Android application to Firebase.
3. Download the Firebase Android configuration file.
4. Place it at:

```text
android/app/google-services.json
```

5. Enable the required Firebase services:
   - Email/Password Authentication
   - Google Sign-In
   - Cloud Firestore

6. Add the required Android SHA-1 and SHA-256 fingerprints in Firebase project settings.
7. Make sure Firestore Security Rules match the application's actual data structure and authentication requirements.

### Important

Do **not** delete Firestore collections simply to fix an application error. First determine whether the problem is caused by application code, authentication, queries, or Firestore Security Rules.

---

## Gemini API Configuration

Keep the Gemini API key outside the source code.

For local development, create a local `dart_defines.json` file:

```json
{
  "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY"
}
```

Run the application with:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

Do not commit `dart_defines.json` to Git.

---

## Install Dependencies

From the project root:

```bash
flutter pub get
```

Then run:

```bash
flutter run
```

If the project requires the Gemini configuration file:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

---

## Android Build

### Debug APK

```bash
flutter build apk
```

### Release APK

```bash
flutter build apk --release --dart-define-from-file=dart_defines.json
```

### Split APKs by ABI

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines.json
```

The generated APK files can be found under:

```text
build/app/outputs/flutter-apk/
```

For a production release, configure proper Android signing credentials before distributing the application.

---

## Security

Never commit private credentials or service-account keys.

Keep files such as these local:

```text
serviceAccountKey.json
dart_defines.json
.env
.env.*
```

Also avoid committing:

- Generated build artifacts
- Local IDE settings
- Temporary files
- Debug credentials
- Firebase service-account private keys

### Firestore Security

Firestore rules should ensure that authenticated users can access only the data they are authorized to access.

For example, resume documents can use an `ownerId` field to associate a resume with its Firebase Authentication user.

Do not use a broad production rule such as:

```text
allow read, write: if request.auth != null;
```

unless that behavior is deliberately intended and the security implications have been fully evaluated.

---

## Development Checklist

Before committing or submitting changes:

- Run `flutter analyze`
- Run available tests
- Test authentication
- Test resume creation
- Test resume editing
- Test resume loading
- Test PDF generation
- Test autocomplete suggestions on Android
- Test autocomplete suggestions on desktop/web
- Test password change validation
- Test account deletion
- Test admin functionality
- Check Firestore Security Rules
- Verify that no credentials are committed

---

## Troubleshooting

### Suggestions work on desktop but not Android

Make sure the latest Android build is installed on the device.

Then run:

```bash
flutter clean
flutter pub get
flutter build apk
```

Install the newly generated APK and test again.

### Firestore permission-denied error

A `permission-denied` error normally means that the request reached Firebase but was rejected by Firestore Security Rules.

Check:

1. The user is authenticated.
2. The requested document path is correct.
3. The user's UID matches the ownership information where required.
4. The Firestore rule allows the requested operation.
5. The latest rules have been published.

Do not delete existing data as the first troubleshooting step.

### Account operations fail after changing Firestore rules

Check every Firestore collection accessed by the operation. Account deletion may involve more than the user's profile document.

---

## Documentation

Detailed code-level documentation is available in:

```text
CODE_DOCUMENTATION.md
```

Use the code documentation together with this README when working on individual modules.

---

## Project Status

ResUniq is an academic/final-year project and is actively developed. Features, UI components, Firebase structure, and APIs may change during development.

---

## License

This project is developed as an academic/final-year project.

Unless a separate license is added to the repository, the source code should not be assumed to be freely reusable or redistributable.
