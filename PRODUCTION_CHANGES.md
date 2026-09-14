# ResUniq production changes

## Applied changes

1. Duplicate Resume now preserves `customFields`, `customFieldLabels`, and `userCustomSections`.
2. Gemini calls were moved out of the Flutter client and into the authenticated Firebase callable function `generateGeminiContent`.
3. The Gemini API key is stored as the Firebase Functions secret `GEMINI_API_KEY`; do not use `--dart-define=GEMINI_API_KEY` anymore.
4. AI calls are authenticated, template-image analysis is admin-only, and each user is limited to 20 AI calls per UTC day.
5. Template images are capped at 6 MB on the backend.
6. Firebase Crashlytics was added for release-mode crash reporting.
7. Added `cloud_functions` and `firebase_crashlytics` dependencies.

## Deploy the backend

From the project root:

```bash
firebase login
firebase use resuniq-ca89d
firebase functions:secrets:set GEMINI_API_KEY
cd functions
npm install
cd ..
firebase deploy --only functions
```

Then refresh Flutter dependencies:

```bash
flutter clean
flutter pub get
```

Build the release APK normally after the backend is deployed.

## App Check

The callable function currently has `enforceAppCheck: false` so the existing app is not broken before App Check providers are configured. The backend still requires Firebase Authentication and has a server-side daily quota. For a public release, configure Firebase App Check for the Android/iOS/web apps and then change the callable option to `enforceAppCheck: true`.

## Google Sign-In

This archive does not contain Android/iOS platform files, so SHA fingerprints, the release signing key, and `google-services.json` could not be changed here. Those must still match the production Android/iOS Firebase app configuration.
