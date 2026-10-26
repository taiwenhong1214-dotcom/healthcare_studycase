// Study assistant backend for the Change Healthcare case study.
//
// Provider order:
//   1. OpenCode Zen (OPENCODE_API_KEY)
//   2. OpenRouter  (OPENROUTER_API_KEY)
//
// The OpenRouter model list matches the earlier project. OpenCode is tried
// first with a paid model, then OpenRouter takes over.
//
// OpenCode's free models only work inside the OpenCode client. External apps
// must use a paid model (or OpenCode Go), so this uses the inexpensive paid
// DeepSeek V4.1 Flash model instead.

const OPENCODE_URL = 'https://opencode.ai/inference/openai/v1/chat/completions';
const OPENCODE_GO_URL =
  'https://opencode.ai/inference/go/openai/v1/chat/completions';
const OPENCODE_MODELS = ['deepseek-v4.1-flash'];

const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';
const OPENROUTER_MODELS = [
  'openai/gpt-oss-120b:free',
  'anthropic/claude-opus-4.8:fast',
  'openai/gpt-5.4-nano',
];

const SYSTEM_PROMPT = `You are the study assistant for an educational case study about the 2024 Change Healthcare ransomware attack.

Help students understand the attack, its impact, and the three security lessons in the case study:
1. Missing MFA: the remote-access portal only required login details.
2. Outdated Systems: old, unsupported software may stop receiving security updates.
3. Poor Network Separation: unnecessary connections let attackers reach other systems.

Case facts:
- Change Healthcare is a subsidiary of UnitedHealth Group.
- In early 2024, attackers used stolen login details to enter a remote-access portal that did not require MFA.
- The attack disrupted healthcare claims and payments across the United States.
- The main defensive lessons are phishing-resistant MFA, regular patching of supported systems, and network segmentation with least-privilege access.

Rules:
- Reply in the same language the student uses.
- Be clear, friendly, and concise (usually under 180 words). Plain language is best.
- Explain concepts rather than just listing facts. Use a short example when it helps.
- Stay within the case study and general security concepts. If you are unsure or the question is outside the material, say so instead of inventing details.
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

async function callOpenCode(
  model,
  messages,
  { url = OPENCODE_URL, headers = {} } = {},
) {
  const apiKey = process.env.OPENCODE_API_KEY;
  if (!apiKey) {
    throw new Error('OPENCODE_API_KEY is not configured');
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
      'User-Agent': 'ChangeHealthcareStudyAssistant/1.0',
      ...headers,
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

  // Temporary deployment diagnostic. Removed once the provider setup is
  // confirmed.
  if (req.method === 'GET') {
    const url = new URL(req.url, 'https://healthcare-studycase.space');
    if (url.searchParams.get('diag') === 'hc-setup-check-8b1f4d') {
      const probe = [{ role: 'user', content: 'Reply with exactly: OK' }];
      const session = crypto.randomUUID();
      const probes = {
        'paid-deepseek': () => callOpenCode('deepseek-v4.1-flash', probe),
        'go-glm-flash': () =>
          callOpenCode('glm-5.3-flash', probe, {
            url: OPENCODE_GO_URL,
            headers: { 'x-opencode-session': session },
          }),
        'go-longcat': () =>
          callOpenCode('longcat-2.0', probe, {
            url: OPENCODE_GO_URL,
            headers: { 'x-opencode-session': session },
          }),
        'go-beam': () =>
          callOpenCode('beam-free', probe, {
            url: OPENCODE_GO_URL,
            headers: { 'x-opencode-session': session },
          }),
      };
      const results = {};
      await Promise.all(
        Object.entries(probes).map(async ([name, run]) => {
          try {
            results[name] = { ok: true, reply: (await run()).slice(0, 80) };
          } catch (error) {
            results[name] = { ok: false, error: error.message };
          }
        }),
      );
      return res.status(200).json({
        keys: {
          opencode: Boolean(process.env.OPENCODE_API_KEY),
          openrouter: Boolean(process.env.OPENROUTER_API_KEY),
        },
        results,
      });
    }
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
