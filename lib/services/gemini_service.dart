/// ---------------------------------------------------------------------------
/// ResUniq - gemini_service.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Application services and repositories. These classes contain Firebase, Gemini, PDF, authentication, profile, and data-access logic so screens can stay focused on UI.
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

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Small client for the Gemini Developer API.
///
/// The API key is supplied at build/run time with:
/// --dart-define=GEMINI_API_KEY=YOUR_KEY
///
/// This keeps the key out of the source code, but it is still part of the
/// Flutter client build. Do not use this client with a production secret.
class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = 'gemini-3.5-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  final http.Client _client;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<String> generateObjective({
    required Map<String, dynamic> resumeDetails,
  }) async {
    final prompt = '''
Write a concise, professional resume professional summary/objective using the
resume details below.

Requirements:
- 2 to 4 sentences.
- Professional and natural.
- Do not invent employers, degrees, years, skills, achievements, or other facts.
- Do not use a heading such as "Objective" or "Summary".
- Return only the paragraph, with no quotation marks and no markdown.

Resume details:
${jsonEncode(resumeDetails)}
''';

    final text = await _generateText([
      {'text': prompt},
    ]);

    return text.trim();
  }

  Future<Map<String, dynamic>> analyzeTemplateImage({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    final encoded = base64Encode(imageBytes);

    const prompt = r'''
Analyze the uploaded resume template image as a visual-design reconstruction task.
Return ONLY valid JSON. Do not use markdown fences or explanations.

Do NOT choose a generic resume style. Infer THIS exact reference image: page composition, columns, header placement, sidebar, section order, alignment, spacing, borders, divider style, profile-photo treatment, and the visible color palette. The goal is for a PDF renderer to reproduce the reference design.

Use exactly these fields:
{
  "name": "short template name",
  "description": "short visual design description",
  "accentHex": "#RRGGBB",
  "backgroundHex": "#RRGGBB",
  "textHex": "#RRGGBB",
  "mutedTextHex": "#RRGGBB",
  "secondaryHex": "#RRGGBB",
  "headerBackgroundHex": "#RRGGBB",
  "headerTextHex": "#RRGGBB",
  "headerAlignment": "left|center|right",
  "headerStyle": "simple|band|accentBand|split",
  "sectionStyle": "rule|accentBar|boxed|plain",
  "profileShape": "circle|square|none",
  "contactStyle": "inline|stacked",
  "columnLayout": "single|twoColumn",
  "sidebarPercent": 30,
  "sidebarBackgroundHex": "#RRGGBB",
  "sidebarTextHex": "#RRGGBB",
  "sidebarSections": ["skills","languages"],
  "fontScale": 1.0,
  "sectionSpacing": 12,
  "lineSpacing": 1.3,
  "layout": "minimal|classic|modern|executive",
  "sectionOrder": ["objective","experience","education","projects","skills","certifications","languages","interests","references"],
  "showProfileImage": true
}

Rules: preserve the dominant colors; use six-digit hex values; detect left/right sidebars and their approximate width; sectionOrder describes only the visual order/placement that can be inferred from the reference. It is NOT a list of fields to include or exclude. sidebarSections contains only sections visibly placed in the sidebar. The Flutter renderer will always supply the actual resume fields from the user form, even when a section is not visible in the reference image. Never use sectionOrder or sidebarSections to decide which user data exists or should be deleted. Use fontScale/sectionSpacing/lineSpacing to match density; do not invent visual elements absent from the image.
''';
    final text = await _generateText([
      {'text': prompt},
      {
        'inline_data': {'mime_type': mimeType, 'data': encoded},
      },
    ]);

    final cleaned = _stripJsonFences(text.trim());
    final decoded = jsonDecode(cleaned);
    if (decoded is! Map) {
      throw const FormatException(
        'The AI service returned an invalid template object.',
      );
    }

    return Map<String, dynamic>.from(decoded);
  }

  Future<String> _generateText(List<Map<String, dynamic>> parts) async {
    if (!isConfigured) {
      throw StateError(
        'AI service configuration is missing. Please check the app configuration.',
      );
    }

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': _apiKey},
      body: jsonEncode({
        'contents': [
          {'role': 'user', 'parts': parts},
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String detail = response.body;
      try {
        final body = jsonDecode(response.body);
        final error = body is Map ? body['error'] : null;
        if (error is Map && error['message'] != null) {
          detail = error['message'].toString();
        }
      } catch (_) {
        // Keep the raw response if it was not JSON.
      }
      throw Exception('AI service error (${response.statusCode}): $detail');
    }

    final body = jsonDecode(response.body);
    final text = _extractResponseText(body);
    if (text.trim().isEmpty) {
      throw const FormatException('The AI service returned an empty response.');
    }
    return text;
  }

  String _extractResponseText(dynamic body) {
    if (body is! Map) return '';
    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';

    final buffer = StringBuffer();
    for (final candidate in candidates) {
      if (candidate is! Map) continue;
      final content = candidate['content'];
      if (content is! Map) continue;
      final parts = content['parts'];
      if (parts is! List) continue;
      for (final part in parts) {
        if (part is Map && part['text'] is String) {
          buffer.write(part['text']);
        }
      }
    }
    return buffer.toString();
  }

  String _stripJsonFences(String value) {
    var result = value.trim();
    if (result.startsWith('```')) {
      result = result.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      result = result.replaceFirst(RegExp(r'\s*```$'), '');
    }
    return result.trim();
  }

  void dispose() => _client.close();
}
