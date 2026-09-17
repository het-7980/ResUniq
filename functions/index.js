const { onCall, HttpsError } = require('firebase-functions/https');
const { defineSecret } = require('firebase-functions/params');
const { setGlobalOptions } = require('firebase-functions/v2');
const { logger } = require('firebase-functions');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { GoogleGenAI } = require('@google/genai');

initializeApp();

setGlobalOptions({
  region: 'us-central1',
  maxInstances: 10,
  memory: '512MiB',
  timeoutSeconds: 90,
});

const geminiApiKey = defineSecret('GEMINI_API_KEY');
const db = getFirestore();
const MODEL = 'gemini-3.6-flash';
const DAILY_LIMIT = 20;
const MAX_IMAGE_BYTES = 6 * 1024 * 1024;

function requireAuthenticated(request) {
  if (!request.auth?.uid) {
    throw new HttpsError(
      'unauthenticated',
      'You must be signed in to use AI features.',
    );
  }
  return request.auth.uid;
}

async function requireAdmin(uid) {
  const snapshot = await db.collection('users').doc(uid).get();
  if (snapshot.data()?.role !== 'admin') {
    throw new HttpsError(
      'permission-denied',
      'Administrator permission is required for template analysis.',
    );
  }
}

async function consumeDailyQuota(uid) {
  const ref = db.collection('ai_usage').doc(uid);
  const day = new Date().toISOString().slice(0, 10);

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const current = snapshot.exists ? snapshot.data() : null;
    const currentDay = current?.day;
    const currentCount = currentDay === day ? Number(current?.count || 0) : 0;

    if (currentCount >= DAILY_LIMIT) {
      throw new HttpsError(
        'resource-exhausted',
        'Daily AI usage limit reached. Please try again tomorrow.',
      );
    }

    transaction.set(
      ref,
      {
        day,
        count: currentCount + 1,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

function buildObjectivePrompt(resumeDetails) {
  return `Write a concise, professional resume professional summary/objective using the resume details below.

Requirements:
- 2 to 4 sentences.
- Professional and natural.
- Do not invent employers, degrees, years, skills, achievements, or other facts.
- Do not use a heading such as "Objective" or "Summary".
- Return only the paragraph, with no quotation marks and no markdown.

Resume details:
${JSON.stringify(resumeDetails)}`;
}

function buildTemplatePrompt() {
  return `Analyze the uploaded resume template image as a visual-design reconstruction task.
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

Rules: preserve the dominant colors; use six-digit hex values; detect left/right sidebars and their approximate width; sectionOrder describes only the visual order/placement that can be inferred from the reference. It is NOT a list of fields to include or exclude. sidebarSections contains only sections visibly placed in the sidebar. The Flutter renderer will always supply the actual resume fields from the user form, even when a section is not visible in the reference image. Never use sectionOrder or sidebarSections to decide which user data exists or should be deleted. Use fontScale/sectionSpacing/lineSpacing to match density; do not invent visual elements absent from the image.`;
}

async function generateContent(parts) {
  const ai = new GoogleGenAI({ apiKey: geminiApiKey.value() });
  const response = await ai.models.generateContent({
    model: MODEL,
    contents: [{ role: 'user', parts }],
  });

  const text = response.text?.trim() || '';
  if (!text) {
    throw new HttpsError('internal', 'The AI service returned an empty response.');
  }
  return text;
}

exports.generateGeminiContent = onCall(
  {
    secrets: [geminiApiKey],
    enforceAppCheck: false,
  },
  async (request) => {
    const uid = requireAuthenticated(request);
    const data = request.data || {};
    const operation = data.operation;

    if (operation !== 'generateObjective' && operation !== 'analyzeTemplateImage') {
      throw new HttpsError('invalid-argument', 'Unsupported AI operation.');
    }

    if (operation === 'analyzeTemplateImage') {
      await requireAdmin(uid);
    }

    await consumeDailyQuota(uid);

    try {
      if (operation === 'generateObjective') {
        if (!data.resumeDetails || typeof data.resumeDetails !== 'object') {
          throw new HttpsError('invalid-argument', 'Resume details are required.');
        }

        const text = await generateContent([
          { text: buildObjectivePrompt(data.resumeDetails) },
        ]);
        return { text };
      }

      const mimeType = String(data.mimeType || '');
      const imageBase64 = String(data.imageBase64 || '');
      if (!mimeType.startsWith('image/') || !imageBase64) {
        throw new HttpsError('invalid-argument', 'A valid template image is required.');
      }

      const imageBytes = Buffer.from(imageBase64, 'base64');
      if (!imageBytes.length || imageBytes.length > MAX_IMAGE_BYTES) {
        throw new HttpsError(
          'invalid-argument',
          'The template image must be between 1 byte and 6 MB.',
        );
      }

      const text = await generateContent([
        { text: buildTemplatePrompt() },
        {
          inlineData: {
            mimeType,
            data: imageBytes.toString('base64'),
          },
        },
      ]);

      let spec;
      try {
        const cleaned = text
          .replace(/^```(?:json)?\s*/i, '')
          .replace(/\s*```$/i, '')
          .trim();
        spec = JSON.parse(cleaned);
      } catch (error) {
        logger.error('Gemini template JSON parse failed', error);
        throw new HttpsError(
          'internal',
          'The AI service returned an invalid template object.',
        );
      }

      if (!spec || typeof spec !== 'object' || Array.isArray(spec)) {
        throw new HttpsError(
          'internal',
          'The AI service returned an invalid template object.',
        );
      }

      return { spec };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error('Gemini request failed', error);
      throw new HttpsError(
        'internal',
        'The AI service is temporarily unavailable. Please try again.',
      );
    }
  },
);
