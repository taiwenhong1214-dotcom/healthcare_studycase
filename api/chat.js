// Study assistant backend for the Change Healthcare case study.
//
// Provider order:
//   1. OpenCode Zen (OPENCODE_API_KEY)
//   2. OpenRouter  (OPENROUTER_API_KEY)
//
// OpenCode is tried first, then OpenRouter takes over. OpenCode's free chat
// models are normally limited to the OpenCode client, so the serverless
// function may receive a 429 and fall back to OpenRouter.

const OPENCODE_URL = 'https://opencode.ai/inference/openai/v1/chat/completions';
const OPENCODE_MODELS = ['deepseek-v4.1-flash-free', 'glm-5.3-flash-free'];

const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';
const OPENROUTER_MODELS = [
  'nvidia/nemotron-3.5-lightning:free',
  'nvidia/nemotron-3-ultra-550b-a55b:free',
];

const SYSTEM_PROMPT = `You are the study assistant for an educational case study about the 2024 Change Healthcare ransomware attack.

Scope:
- Answer only questions about this case study: the attack, its impact, the three vulnerabilities, and the defenses covered.
- The three lessons are:
  1. Missing MFA: the remote-access portal only required login details.
  2. Outdated Systems: old, unsupported software may stop receiving security updates.
  3. Poor Network Separation: unnecessary connections let attackers reach other systems.
- You may explain a general security term only when it directly helps the student understand a lesson or fact in this case study.
- If a question is unrelated, briefly say you can only help with this case study, then invite a case-study question. Do not answer the unrelated question.

Case facts:
- Change Healthcare is a subsidiary of UnitedHealth Group.
- In early 2024, attackers used stolen login details to enter a remote-access portal that did not require MFA.
- The attack disrupted healthcare claims and payments across the United States.
- The main defensive lessons are phishing-resistant MFA, regular patching of supported systems, and network segmentation with least-privilege access.

Length:
- Follow any length the student asks for: a word count, a sentence count, a number of bullet points, "briefly", or "in detail". Stay at or under a stated word limit.
- When a word limit is given, count your draft and revise it before replying so it stays at or under the limit.
- If the student gives no length, match the question: 1-3 sentences for a simple fact, up to 120 words for an explanation. Do not pad.
- If a requested limit is very short, give the direct answer first and drop optional detail.
- If the request cannot be answered well within the limit, say so in one short sentence and give the best answer that fits.

Style and safety:
- Reply in the same language the student uses.
- Be clear, friendly, and plain. Explain rather than just listing facts. Use a short example when it helps.
- Never invent facts. If the case study does not cover something, say so.
- Never claim to have live information about the attack, and never ask for personal or sensitive information.
- Do not use markdown tables. Short paragraphs and simple bullet points are fine.
- You are a study helper, not a doctor or a source of medical advice.`;

function sanitizeMessages(rawMessages) {
  if (!Array.isArray(rawMessages)) return [];

  return rawMessages
    .filter((message) => message && typeof message.content === 'string')
    .slice(-12)
    .map((message) => ({
      role: message.role === 'assistant' ? 'assistant' : 'user',
      content: message.content.trim().slice(0, 4000),
    }))
    .filter((message) => message.content.length > 0);
}

async function callOpenCode(model, messages) {
  const apiKey = process.env.OPENCODE_API_KEY;
  if (!apiKey) {
    throw new Error('OPENCODE_API_KEY is not configured');
  }

  const response = await fetch(OPENCODE_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
      'User-Agent': 'ChangeHealthcareStudyAssistant/1.0',
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: 0.5,
      stream: false,
    }),
    signal: AbortSignal.timeout(15000),
  });

  if (!response.ok) {
    const details = (await response.text()).slice(0, 300);
    throw new Error(`OpenCode ${model} returned ${response.status}: ${details}`);
  }

  const data = await response.json();
  const reply = data?.choices?.[0]?.message?.content;
  if (typeof reply !== 'string' || reply.trim().length === 0) {
    throw new Error(`OpenCode ${model} returned an empty reply`);
  }
  return reply.trim();
}

async function callOpenRouter(messages) {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey) {
    throw new Error('OPENROUTER_API_KEY is not configured');
  }

  const response = await fetch(OPENROUTER_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
      'HTTP-Referer': 'https://healthcare-studycase.space',
      'X-Title': 'Change Healthcare Study Assistant',
    },
    body: JSON.stringify({
      models: OPENROUTER_MODELS,
      messages,
      temperature: 0.5,
      stream: false,
    }),
    signal: AbortSignal.timeout(30000),
  });

  if (!response.ok) {
    const details = (await response.text()).slice(0, 300);
    throw new Error(`OpenRouter returned ${response.status}: ${details}`);
  }

  const data = await response.json();
  const reply = data?.choices?.[0]?.message?.content;
  if (typeof reply !== 'string' || reply.trim().length === 0) {
    throw new Error('OpenRouter returned an empty reply');
  }
  return {
    reply: reply.trim(),
    model: data?.model || OPENROUTER_MODELS[0],
  };
}

module.exports = async function handler(req, res) {
  // The app calls the function same-origin. Allow the deployed domain,
  // Vercel previews, and local Flutter development explicitly instead of
  // opening the endpoint to every website.
  const origin = req.headers.origin || '';
  const allowedOrigin =
    origin === 'https://healthcare-studycase.space' ||
    origin === 'https://www.healthcare-studycase.space' ||
    /^https:\/\/[a-z0-9-]+\.vercel\.app$/i.test(origin) ||
    /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin);

  if (allowedOrigin) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Cache-Control', 'no-store');

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  let body = req.body;
  if (typeof body === 'string') {
    try {
      body = JSON.parse(body);
    } catch {
      return res.status(400).json({ error: 'Invalid JSON body' });
    }
  }

  const history = sanitizeMessages(body?.messages);
  if (history.length === 0) {
    return res.status(400).json({ error: 'At least one message is required' });
  }
  if (history[history.length - 1].role !== 'user') {
    return res.status(400).json({ error: 'The last message must be from the user' });
  }

  const messages = [{ role: 'system', content: SYSTEM_PROMPT }, ...history];
  const failures = [];

  try {
    for (const model of OPENCODE_MODELS) {
      try {
        const reply = await callOpenCode(model, messages);
        return res.status(200).json({
          reply,
          provider: 'opencode',
          model,
        });
      } catch (error) {
        console.warn(`[chat] OpenCode ${model} failed:`, error.message);
        failures.push({ provider: 'opencode', model, error: error.message });
      }
    }
  } catch (error) {
    console.warn('[chat] OpenCode failed:', error.message);
    failures.push({ provider: 'opencode', error: error.message });
  }

  try {
    const result = await callOpenRouter(messages);
    return res.status(200).json({
      reply: result.reply,
      provider: 'openrouter',
      model: result.model,
    });
  } catch (error) {
    console.error('[chat] OpenRouter failed:', error.message);
    failures.push({ provider: 'openrouter', error: error.message });
  }

  return res.status(502).json({
    error: 'The study assistant is temporarily unavailable. Please try again.',
    failures,
  });
};

module.exports.config = {
  maxDuration: 60,
};
