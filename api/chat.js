// Study assistant backend for the Change Healthcare case study.
//
// Performance strategy:
//   - Race all providers/models in parallel — first successful reply wins.
//   - Compact system prompt to reduce input tokens and generation latency.
//   - Cap output with max_tokens to prevent rambling on free-tier models.
//   - Stream the response so the user sees tokens as they arrive.
//
// Provider order (raced in parallel):
//   1. OpenCode Zen (OPENCODE_API_KEY)
//   2. OpenRouter  (OPENROUTER_API_KEY)

const OPENCODE_URL = 'https://opencode.ai/inference/openai/v1/chat/completions';
const OPENCODE_MODELS = ['deepseek-v4.1-flash-free', 'beam-free'];

const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';
const OPENROUTER_MODELS = [
  'nvidia/nemotron-3-ultra-550b-a55b:free',
  'thinkingmachines/inkling:free'

];

// ── Compact system prompt ──────────────────────────────────────────────
// Strictly enforces neat, structured, and aligned responses (整齐规整).
const SYSTEM_PROMPT = `You are the study assistant for the 2024 Change Healthcare ransomware attack case study.

Scope & facts (answer ONLY about this case):
• Change Healthcare (UnitedHealth Group subsidiary) was hit by ransomware in early 2024, disrupting nationwide US healthcare claims and payments.
• Three core vulnerabilities & lessons:
  1. Missing MFA: The remote-access portal only required credentials with no multi-factor authentication.
  2. Outdated Systems: Legacy server systems lacked critical security updates and patches.
  3. Poor Network Separation: Flat network design allowed attackers to spread laterally across systems.
• Defenses: Phishing-resistant MFA, continuous patching of supported software, and strict network segmentation with least-privilege access.
• If off-topic: Politely state in 1 sentence that you can only assist with the Change Healthcare case study.

Output Format & Layout (MUST be clean, neat, and well-aligned / 整齐规整):
• Keep answers structured, tidy, and easy to skim.
• For explanations or multi-point answers, structure cleanly:
  - Start with a direct 1-sentence summary.
  - Use clean bullet points (•) or numbered lists (1., 2., 3.).
  - Format each point with a clear bold label, e.g.:
    • **Point Title**: Brief, focused explanation.
  - Keep each bullet point to 1-2 concise sentences.
• For simple facts: Answer directly in 1-2 sentences without padding.
• Do not output walls of unbroken text. Separate distinct thoughts with a single blank line.
• Do not use markdown headers (###), raw HTML, or tables.
• No conversational fluff (avoid "Sure!", "Here is...", or "Hope this helps!").
• Always match the student's language (e.g., reply in clean, well-structured Chinese if asked in Chinese).`;

// ── Helpers ─────────────────────────────────────────────────────────────

function formatCleanReply(text) {
  if (typeof text !== 'string') return '';
  return text
    .replace(/\r\n/g, '\n')
    // Remove markdown headers (### Header -> Header)
    .replace(/^#{1,6}\s+/gm, '')
    // Normalize bullets (* or - at line start -> •)
    .replace(/^[\t ]*[-*]\s+/gm, '• ')
    // Collapse 3+ consecutive newlines to 2
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

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

// ── Streaming helpers ──────────────────────────────────────────────────

/** Parse one SSE chunk and return the content delta, or null. */
function extractDelta(line) {
  if (!line.startsWith('data: ')) return null;
  const payload = line.slice(6).trim();
  if (payload === '[DONE]') return null;
  try {
    const parsed = JSON.parse(payload);
    return parsed?.choices?.[0]?.delta?.content ?? null;
  } catch {
    return null;
  }
}

/**
 * Call a single model with streaming enabled. Returns a Promise that
 * resolves with the full reply text. While streaming, each delta token
 * is forwarded to `onDelta(token)`.
 */
async function callModelStreaming({ url, model, messages, headers, timeoutMs, onDelta }) {
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: 0.5,
      max_tokens: 300,
      stream: true,
    }),
    signal: AbortSignal.timeout(timeoutMs),
  });

  if (!response.ok) {
    const details = (await response.text()).slice(0, 300);
    throw new Error(`${model} returned ${response.status}: ${details}`);
  }

  // Read the SSE stream.
  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  let fullReply = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split('\n');
    // Keep the last (possibly incomplete) line in the buffer.
    buffer = lines.pop() || '';

    for (const line of lines) {
      const delta = extractDelta(line);
      if (delta) {
        fullReply += delta;
        onDelta(delta);
      }
    }
  }
  // Process any remaining data in the buffer.
  if (buffer.trim()) {
    const delta = extractDelta(buffer);
    if (delta) {
      fullReply += delta;
      onDelta(delta);
    }
  }

  if (fullReply.trim().length === 0) {
    throw new Error(`${model} returned an empty reply`);
  }
  return fullReply.trim();
}

// ── Non-streaming fallback (used when streaming is not requested) ──────

async function callModelJSON({ url, model, messages, headers, timeoutMs }) {
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: 0.5,
      max_tokens: 300,
      stream: false,
    }),
    signal: AbortSignal.timeout(timeoutMs),
  });

  if (!response.ok) {
    const details = (await response.text()).slice(0, 300);
    throw new Error(`${model} returned ${response.status}: ${details}`);
  }

  const data = await response.json();
  const reply = data?.choices?.[0]?.message?.content;
  if (typeof reply !== 'string' || reply.trim().length === 0) {
    throw new Error(`${model} returned an empty reply`);
  }
  return { reply: reply.trim(), model: data?.model || model };
}

// ── Build per-provider headers ─────────────────────────────────────────

function openCodeHeaders() {
  const apiKey = process.env.OPENCODE_API_KEY;
  if (!apiKey) throw new Error('OPENCODE_API_KEY is not configured');
  return {
    Authorization: `Bearer ${apiKey}`,
    'User-Agent': 'ChangeHealthcareStudyAssistant/1.0',
  };
}

function openRouterHeaders() {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey) throw new Error('OPENROUTER_API_KEY is not configured');
  return {
    Authorization: `Bearer ${apiKey}`,
    'HTTP-Referer': 'https://healthcare-studycase.space',
    'X-Title': 'Change Healthcare Study Assistant',
  };
}

// ── Main handler ───────────────────────────────────────────────────────

module.exports = async function handler(req, res) {
  // CORS — allow deployed domain, Vercel previews, and local dev.
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

  // ── Streaming path ─────────────────────────────────────────────────
  // If the client sends `Accept: text/event-stream` or `?stream=1`,
  // stream SSE tokens directly. Otherwise fall back to the JSON path
  // so the existing Flutter client keeps working without changes.
  const wantsStream =
    req.headers.accept === 'text/event-stream' ||
    (req.query && req.query.stream === '1');

  if (wantsStream) {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();

    // Build all model attempts.
    const attempts = [];
    try {
      const ocHeaders = openCodeHeaders();
      for (const m of OPENCODE_MODELS) {
        attempts.push({ url: OPENCODE_URL, model: m, headers: ocHeaders, timeoutMs: 10000 });
      }
    } catch { /* key not set — skip */ }
    try {
      const orHeaders = openRouterHeaders();
      for (const m of OPENROUTER_MODELS) {
        attempts.push({ url: OPENROUTER_URL, model: m, headers: orHeaders, timeoutMs: 12000 });
      }
    } catch { /* key not set — skip */ }

    if (attempts.length === 0) {
      res.write('data: {"error":"No API keys configured"}\n\n');
      return res.end();
    }

    // Race all models in parallel. The first one to start producing
    // tokens wins; the rest are left to settle (and ignored).
    let settled = false;
    const racePromises = attempts.map(
      (a) =>
        callModelStreaming({
          ...a,
          messages,
          onDelta: (token) => {
            if (!settled) {
              settled = true;
              // Cancel interest in other promises (they'll still run
              // but their deltas will be ignored below).
            }
            // Only forward deltas from the winning model.
            if (settled) {
              res.write(`data: ${JSON.stringify({ token })}\n\n`);
            }
          },
        }).then((fullReply) => ({ ok: true, reply: fullReply, model: a.model })),
    );

    // We need the *first to succeed*, not Promise.race (which resolves
    // on the first to settle, including rejections). Use Promise.any.
    try {
      const winner = await Promise.any(racePromises);
      res.write(`data: ${JSON.stringify({ done: true, model: winner.model })}\n\n`);
    } catch (aggregateError) {
      res.write(`data: ${JSON.stringify({ error: 'All models failed' })}\n\n`);
    }
    return res.end();
  }

  // ── JSON path (existing Flutter client) ────────────────────────────
  // Race all providers/models in parallel — first success wins.

  const attempts = [];
  try {
    const ocHeaders = openCodeHeaders();
    for (const m of OPENCODE_MODELS) {
      attempts.push(
        callModelJSON({ url: OPENCODE_URL, model: m, messages, headers: ocHeaders, timeoutMs: 10000 })
          .then((r) => ({ ...r, provider: 'opencode' })),
      );
    }
  } catch { /* key not set — skip */ }
  try {
    const orHeaders = openRouterHeaders();
    for (const m of OPENROUTER_MODELS) {
      attempts.push(
        callModelJSON({ url: OPENROUTER_URL, model: m, messages, headers: orHeaders, timeoutMs: 12000 })
          .then((r) => ({ ...r, provider: 'openrouter' })),
      );
    }
  } catch { /* key not set — skip */ }

  if (attempts.length === 0) {
    return res.status(500).json({ error: 'No API keys configured' });
  }

  try {
    const winner = await Promise.any(attempts);
    return res.status(200).json({
      reply: formatCleanReply(winner.reply),
      provider: winner.provider,
      model: winner.model,
    });
  } catch (aggregateError) {
    const failures = (aggregateError.errors || []).map((e) => e.message);
    console.error('[chat] All models failed:', failures);
    return res.status(502).json({
      error: 'The study assistant is temporarily unavailable. Please try again.',
      failures,
    });
  }
};

module.exports.config = {
  maxDuration: 60,
};
