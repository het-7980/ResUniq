/// ---------------------------------------------------------------------------
/// ResUniq - gemini_service.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Secure client for the application's Gemini features.
///
/// Production architecture:
/// Flutter -> Firebase Auth -> callable Cloud Function -> Gemini API
///
/// The Gemini API key is intentionally NOT shipped in the Flutter application.
/// The key is stored as a Firebase Functions secret on the server.
/// ---------------------------------------------------------------------------
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

class GeminiService {
  GeminiService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: _region);

  static const String _region = 'us-central1';
  static const String _functionName = 'generateGeminiContent';

  final FirebaseFunctions _functions;

  /// The AI feature is configured on the server, not in the APK.
  bool get isConfigured => true;

  Future<String> generateObjective({
    required Map<String, dynamic> resumeDetails,
  }) async {
    final result = await _call({
      'operation': 'generateObjective',
      'resumeDetails': resumeDetails,
    });

    final text = result['text']?.toString().trim() ?? '';
    if (text.isEmpty) {
      throw const FormatException(
        'The AI service returned an empty professional summary.',
      );
    }
    return text;
  }

  Future<Map<String, dynamic>> analyzeTemplateImage({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    if (imageBytes.isEmpty) {
      throw const FormatException('The template image is empty.');
    }

    final result = await _call({
      'operation': 'analyzeTemplateImage',
      'mimeType': mimeType,
      'imageBase64': base64Encode(imageBytes),
    });

    final spec = result['spec'];
    if (spec is! Map) {
      throw const FormatException(
        'The AI service returned an invalid template object.',
      );
    }

    return Map<String, dynamic>.from(spec);
  }

  Future<Map<String, dynamic>> _call(Map<String, dynamic> data) async {
    try {
      final callable = _functions.httpsCallable(
        _functionName,
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 90),
        ),
      );
      final response = await callable.call(data);
      final value = response.data;
      if (value is! Map) {
        throw const FormatException(
          'The AI service returned an invalid response.',
        );
      }
      return Map<String, dynamic>.from(value);
    } on FirebaseFunctionsException catch (e) {
      final message = e.message?.trim();
      throw Exception(
        message == null || message.isEmpty
            ? 'AI service error (${e.code}). Please try again.'
            : message,
      );
    }
  }
}
