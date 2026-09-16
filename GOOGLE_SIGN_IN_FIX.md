# Google Sign-In fix

The Dart Google authentication service was updated for the current `google_sign_in` 7.x API.

## Important Android setup

This uploaded ZIP contains only the `lib/` source folder, so the Android Firebase configuration files were not included. The code alone cannot supply the Android OAuth credentials.

For Android, verify:

1. Google is enabled in Firebase Authentication.
2. Your Android app's package/application ID exactly matches the Firebase Android app.
3. The SHA-1 and SHA-256 fingerprints for the build you are running are registered in Firebase.
4. Download a fresh `google-services.json` after adding/updating the fingerprints and place it in `android/app/`.
5. The downloaded JSON contains a Web OAuth client (`client_type: 3`).
6. Run `flutter clean`, then `flutter pub get`, then run the app again.

If the button still fails, the updated error message now distinguishes a Google client-configuration problem from a normal user cancellation.
