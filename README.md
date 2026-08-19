# ResUniq 📄✨

> An AI-powered resume builder built with Flutter, Firebase, and Gemini.

ResUniq is a modern resume-building application that helps users create professional resumes using customizable templates and AI-assisted content generation.

Users can create, edit, preview, and download resumes while administrators can manage users, resumes, and resume templates through a dedicated admin dashboard.

---

## 🚀 Features

### 👤 User Features

- 🔐 Email & Password Authentication
- 🔵 Google Sign-In
- 👤 User Profile Management
- 📝 Create Resume
- ✏️ Edit Resume
- 🗂️ Manage Multiple Resumes
- 💼 Job Role Selection
- 🤖 AI-assisted Resume Content Generation
- 🎨 Multiple Resume Templates
- 👁️ In-App Resume Preview
- 📄 PDF Resume Generation
- 📥 Resume Download
- 🗑️ Resume Management
- ✅ Form Validation
- 📱 Responsive Flutter UI
- ✨ Smooth Animations and Transitions

---

## 🤖 AI Features

ResUniq integrates Google's Gemini API to provide AI-assisted resume generation.

AI functionality can be used for tasks such as:

- Professional resume objectives
- Job-role-based content
- Resume/template-related generation
- Improving the quality of resume content

The application controls the resume form structure while Gemini assists with the appropriate AI-generated content.

---

## 👨‍💼 Admin Features

ResUniq includes a dedicated admin dashboard.

Administrators can:

- 👥 Manage Users
- 📄 Manage User Resumes
- 🎨 Manage Resume Templates
- 👁️ Preview Templates
- 👁️ Preview User Resumes
- 🧪 Preview templates using sample/random data
- 🔐 Access admin-only functionality

Admin access is controlled through the user's role stored in Firebase/Firestore.

---

## 🎨 Resume Templates

Templates are designed to provide different visual styles for resumes.

The application separates:

````text
Resume Data
      +
Template Design
      ↓
PDF Generator
      ↓
Final Resume

👁️ Resume Preview

ResUniq provides an in-app resume preview instead of immediately opening the system print dialog.

The flow is:

Resume
   ↓
PDF Generation
   ↓
In-App Preview
   ↓
View Resume
   ↓
Download if required

The preview is available to both users and administrators.

🔥 Firebase

Firebase is used as the backend infrastructure.

Firebase services used
Firebase Authentication
Google Authentication
Cloud Firestore

Firebase Authentication handles user authentication, while Firestore stores application data such as:

Users
Resumes
Templates
Roles
🧠 Gemini API

ResUniq uses the Gemini API for AI-assisted functionality.

The Gemini API key should never be committed to the repository.

The application should receive the key through a local environment/configuration mechanism such as:

--dart-define

or:

--dart-define-from-file

Example:

flutter build apk --release \
  --dart-define-from-file=dart_defines.json
Example configuration

Create a local file named:

dart_defines.json
{
  "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY"
}

Then add the file to .gitignore.

⚠️ Never commit your real Gemini API key to GitHub.

🛠️ Technologies Used
Technology	Purpose
Flutter	Application framework
Dart	Programming language
Firebase Authentication	User authentication
Cloud Firestore	Database
Google Sign-In	Google authentication
Gemini API	AI-assisted content generation
PDF generation	Resume document generation
Android Studio / VS Code	Development
Node.js	Admin creation utility
📁 Project Structure
ResUniq/
│
├── android/                  # Android configuration
├── ios/                      # iOS configuration
│
├── lib/
│   ├── models/               # Application data models
│   ├── providers/            # State management
│   ├── screens/              # Application screens
│   ├── services/             # Firebase, Gemini and other services
│   ├── widgets/              # Reusable UI components
│   └── main.dart             # Application entry point
│
├── assets/                   # Images, icons and other assets
│
├── create-admin/             # Utility for creating Firebase admins
│
├── test/                     # Tests
│
├── CODE_DOCUMENTATION.md     # Detailed code documentation
├── pubspec.yaml              # Flutter dependencies/configuration
├── pubspec.lock              # Locked dependency versions
├── analysis_options.yaml     # Dart analyzer configuration
└── README.md                 # Project documentation
⚙️ Requirements

Before running the project, install:

Flutter SDK
Dart SDK (included with Flutter)
Android Studio or VS Code
Android SDK
Git
Firebase project
Node.js & npm (only required for the admin creation utility)

Check Flutter installation:

flutter doctor
📥 Installation
1. Clone the Repository
git clone https://github.com/het-7980/ResUniq.git

Navigate into the project:

cd ResUniq
2. Install Flutter Dependencies
flutter pub get
🔥 Firebase Configuration

Create/configure a Firebase project and enable:

Firebase Authentication
Email/Password authentication
Google Sign-In
Cloud Firestore

For Android, configure the Firebase Android application and place the required Firebase configuration file in:

android/app/google-services.json

Also configure the appropriate SHA-1/SHA-256 fingerprints for Google Sign-In.

🔵 Google Sign-In Configuration

For Google Sign-In to work on Android:

Create/configure the Android application in Firebase.
Add the application's SHA-1 fingerprint.
Add the SHA-256 fingerprint.
Enable Google Sign-In in Firebase Authentication.
Download the updated google-services.json.
Replace the existing configuration file in:
android/app/google-services.json

Then rebuild the application.

🤖 Gemini Configuration

Create a local configuration file:

dart_defines.json

Example:

{
  "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY"
}

Do not commit this file.

Add:

dart_defines.json

to .gitignore.

▶️ Running the Application

After configuring Firebase and Gemini:

flutter clean
flutter pub get
flutter run --dart-define-from-file=dart_defines.json

You can also run the application from VS Code after configuring the appropriate launch configuration.

📦 Building the APK

For a release APK:

flutter clean
flutter pub get
flutter build apk --release --dart-define-from-file=dart_defines.json

The generated APK will normally be available at:

build/app/outputs/flutter-apk/app-release.apk
📱 Build APK by Architecture

To generate separate APKs for different Android architectures:

flutter build apk --release --split-per-abi \
  --dart-define-from-file=dart_defines.json

The generated APKs will be located in:

build/app/outputs/flutter-apk/
👨‍💼 Creating an Admin

The repository contains a separate Node.js utility:

create-admin/

This utility creates an administrator using Firebase Admin SDK.

Navigate into the directory:

cd create-admin

Install dependencies:

npm install

The Firebase Admin service-account credentials are required to run the utility.

⚠️ Never commit the Firebase service-account private key to GitHub.

The service account file should remain local and should be listed in .gitignore.

After configuring the credentials, run:

node create-admin.js

The utility creates the Firebase Authentication user and associates the appropriate admin role with the user's Firebase UID.

🔐 Security

Never commit sensitive credentials to GitHub.

The following files should remain private:

serviceAccountKey.json
dart_defines.json
.env
.env.*

Also do not commit:

API keys
Private keys
Passwords
Client secrets
Firebase service-account credentials

A recommended .gitignore includes:

# Flutter
.dart_tool/
.packages
.pub/
build/


# IDE
.idea/
.vscode/


# Node
node_modules/


# Secrets
serviceAccountKey.json
**/serviceAccountKey.json
dart_defines.json
.env
.env.*


# Generated APKs
*.apk
*.aab
⚠️ API Key Note

The Gemini API key is supplied to the Flutter application at build/run time.

For example:

flutter run \
  --dart-define-from-file=dart_defines.json

However, compile-time API keys included in a client application should not be considered completely secret because someone with access to the application may potentially extract them.

For a production deployment, a backend service should be considered so that the Gemini API key remains server-side.

🧪 Code Analysis

Before committing changes, run:

flutter analyze

The project should ideally have no analyzer errors.

🧹 Clean Build

If you encounter Flutter/Gradle build problems, try:

flutter clean
flutter pub get

Then rebuild:

flutter build apk --release \
  --dart-define-from-file=dart_defines.json
📚 Documentation

Detailed code documentation is available in:

CODE_DOCUMENTATION.md

It explains the responsibilities of the major Dart files, classes, services, screens, widgets, and application components.

This documentation is intended to make the project easier to understand for new or beginner developers.

🔄 Application Workflow

The basic user workflow is:

Launch App
    ↓
Login / Sign Up
    ↓
Firebase Authentication
    ↓
User Home
    ↓
Create Resume
    ↓
Fill Resume Information
    ↓
Validation
    ↓
Select Job Role
    ↓
AI-Assisted Content
    ↓
Choose Template
    ↓
Preview
    ↓
Save Resume
    ↓
My Resumes
    ↓
Edit / Preview / Download

The admin workflow is:

Admin Login
    ↓
Firebase Authentication
    ↓
Role Verification
    ↓
Admin Dashboard
    ↓
Manage Users
    ↓
Manage Resumes
    ↓
Manage Templates
    ↓
Preview
🏗️ Architecture Overview

The application follows a layered Flutter architecture.

UI / Screens
     ↓
Widgets
     ↓
Providers / State
     ↓
Services
     ↓
Firebase / Gemini
     ↓
Data
Models

Represent application data.

Screens

Contain the main application pages and user interfaces.

Widgets

Reusable UI components.

Providers

Manage application state and data flow.

Services

Handle external functionality such as:

Firebase
Gemini
PDF generation
Authentication
Data operations
👥 Team Development

When contributing to the project:

Create a new branch.
Make your changes.
Run flutter analyze.
Test the application.
Make sure no secrets are included.
Commit your changes.
Push the branch.
Create a Pull Request.

Example:

git checkout -b feature/new-feature


flutter analyze


git add .


git commit -m "Add new feature"


git push origin feature/new-feature
📌 Important

Before pushing code to GitHub, verify that the following are NOT included:

❌ serviceAccountKey.json
❌ dart_defines.json
❌ API keys
❌ Passwords
❌ Private keys
❌ .idea/
❌ .vscode/launch.json
❌ build/
❌ .dart_tool/
❌ node_modules/
📄 License

Add your preferred license here.

For example:

This project is developed as an academic/final-year project.
👨‍💻 Project

ResUniq

AI-Powered Resume Builder

Built with:

Flutter • Dart • Firebase • Gemini



### A few things I would change before you publish it


Since this is your **final completed ResUniq project**, I'd also add these files to the repository:


```text
README.md
CODE_DOCUMENTATION.md
.gitignore

And I'd not upload:

.idea/
.vscode/
dart_defines.json
serviceAccountKey.json
build/
.dart_tool/
node_modules/
````

#   R e s U n i q 
 
 
#   R e s U n i q  
 