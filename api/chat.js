// Study assistant backend for the Change Healthcare case study.
//
// Performance & quota strategy:
//   - Fallback sequence: try models one-by-one sequentially to conserve API quota.
//   - First successful reply is returned immediately; remaining models are never called.
//   - Compact system prompt to reduce input tokens and generation latency.
//   - Cap output with max_tokens to prevent rambling on free-tier models.
//   - Stream the response if requested by client.
//
// Fallback order (sequential):
//   1. OpenCode Zen: deepseek-v4.1-flash-free
//   2. OpenCode Zen: beam-free
//   3. OpenRouter: nvidia/nemotron-3-ultra-550b-a55b:free
//   4. OpenRouter: thinkingmachines/inkling:free

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
• NEVER use asterisks (*, **, or ***) anywhere in your output. Do not use asterisks for bold or italics.
• For explanations or multi-point answers, structure cleanly:
  - Start with a direct 1-sentence summary.
  - Use clean bullet points (•) or numbered lists (1., 2., 3.).
  - Format each point with a clean title and colon in plain text, e.g.:
    • Point Title: Brief, focused explanation.
  - Keep each bullet point to 1-2 concise sentences.
• Length guidance: Follow any requested length (e.g., "in 150 words"). If no length is specified, provide an informative explanation of around 100-150 words with clear bullet points. For simple facts, 1-2 direct sentences are enough.
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
    // Normalize bullets (* or - or • at line start -> •)
    .replace(/^[\t ]*[-*•]\s*/gm, '• ')
    // Strip all asterisks (*, **, ***) completely
    .replace(/\*+/g, '')
    // Clean up duplicate bullet symbols
    .replace(/^(•\s*)+/gm, '• ')
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
      max_tokens: 500,
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
      max_tokens: 500,
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

// ── IP Rate Limiter ────────────────────────────────────────────────────
// Policy: Max 10 requests / minute per IP + minimum 3s cooldown between requests.
const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 60 seconds
const MAX_REQUESTS_PER_WINDOW = 10;
const COOLDOWN_MS = 3 * 1000; // 3 seconds

const ipRateMap = new Map();

function getClientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded.split(',')[0].trim();
  }
  return req.headers['x-real-ip'] || req.socket?.remoteAddress || '127.0.0.1';
}

function checkRateLimit(ip) {
  const now = Date.now();
  const record = ipRateMap.get(ip) || { timestamps: [], lastRequest: 0 };

  // 1. Cooldown check: minimum 3s between requests
  if (record.lastRequest && (now - record.lastRequest) < COOLDOWN_MS) {
    const waitSeconds = Math.ceil((COOLDOWN_MS - (now - record.lastRequest)) / 1000);
    return {
      allowed: false,
      retryAfter: waitSeconds,
      message: `Please wait ${waitSeconds}s before asking another question.`,
    };
  }

  // 2. Sliding window check: max 10 requests per 60 seconds
  const recent = record.timestamps.filter((ts) => now - ts < RATE_LIMIT_WINDOW_MS);
  if (recent.length >= MAX_REQUESTS_PER_WINDOW) {
    const waitSeconds = Math.ceil((RATE_LIMIT_WINDOW_MS - (now - recent[0])) / 1000);
    return {
      allowed: false,
      retryAfter: waitSeconds,
      message: `Rate limit reached (max 10 questions/minute). Please wait ${waitSeconds}s before asking again.`,
    };
  }

  // Record allowed request
  recent.push(now);
  ipRateMap.set(ip, {
    timestamps: recent,
    lastRequest: now,
  });

  // Keep memory bounded across long-running serverless instances
  if (ipRateMap.size > 1000) {
    for (const [key, val] of ipRateMap.entries()) {
      if (now - val.lastRequest > RATE_LIMIT_WINDOW_MS) {
        ipRateMap.delete(key);
      }
    }
  }

  return { allowed: true };
}

// ── Candidate models builder ───────────────────────────────────────────
// Returns an ordered list of candidate models to try sequentially.
function getCandidates() {
  const candidates = [];
  try {
    const ocHeaders = openCodeHeaders();
    for (const model of OPENCODE_MODELS) {
      candidates.push({
        provider: 'opencode',
        url: OPENCODE_URL,
        model,
        headers: ocHeaders,
        timeoutMs: 10000,
      });
    }
  } catch { /* key not set — skip */ }

  try {
    const orHeaders = openRouterHeaders();
    for (const model of OPENROUTER_MODELS) {
      candidates.push({
        provider: 'openrouter',
        url: OPENROUTER_URL,
        model,
        headers: orHeaders,
        timeoutMs: 12000,
      });
    }
  } catch { /* key not set — skip */ }

  return candidates;
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

  // Server-side rate limiting: 5 req/min per IP + 3s cooldown
  const clientIp = getClientIp(req);
  const rateLimit = checkRateLimit(clientIp);
  if (!rateLimit.allowed) {
    res.setHeader('Retry-After', String(rateLimit.retryAfter));
    return res.status(429).json({ error: rateLimit.message });
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
    const candidates = getCandidates();
    if (candidates.length === 0) {
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Connection', 'keep-alive');
      res.write('data: {"error":"No API keys configured"}\n\n');
      return res.end();
    }

    const failures = [];
    for (const candidate of candidates) {
      let headersSent = false;
      let hasStreamedToken = false;
      try {
        await callModelStreaming({
          url: candidate.url,
          model: candidate.model,
          messages,
          headers: candidate.headers,
          timeoutMs: candidate.timeoutMs,
          onDelta: (token) => {
            if (!headersSent) {
              res.setHeader('Content-Type', 'text/event-stream');
              res.setHeader('Connection', 'keep-alive');
              res.flushHeaders?.();
              headersSent = true;
            }
            hasStreamedToken = true;
            res.write(`data: ${JSON.stringify({ token })}\n\n`);
          },
        });

        if (headersSent) {
          res.write(`data: ${JSON.stringify({ done: true, model: candidate.model })}\n\n`);
          return res.end();
        }
      } catch (err) {
        console.warn(`[chat stream] ${candidate.provider}:${candidate.model} failed:`, err.message);
        failures.push(`${candidate.model}: ${err.message}`);
        // If tokens have already streamed to the client, abort rather than mixing streams
        if (hasStreamedToken) {
          res.write(`data: ${JSON.stringify({ error: 'Stream interrupted' })}\n\n`);
          return res.end();
        }
      }
    }

    if (!res.headersSent) {
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Connection', 'keep-alive');
      res.flushHeaders?.();
    }
    res.write(`data: ${JSON.stringify({ error: 'All models failed', failures })}\n\n`);
    return res.end();
  }

  // ── JSON path (existing Flutter client) ────────────────────────────
  // Try models sequentially — first success returns immediately to conserve quota.

  const candidates = getCandidates();
  if (candidates.length === 0) {
    return res.status(500).json({ error: 'No API keys configured' });
  }

  const failures = [];
  for (const candidate of candidates) {
    try {
      const result = await callModelJSON({
        url: candidate.url,
        model: candidate.model,
        messages,
        headers: candidate.headers,
        timeoutMs: candidate.timeoutMs,
      });

      return res.status(200).json({
        reply: formatCleanReply(result.reply),
        provider: candidate.provider,
        model: result.model,
      });
    } catch (err) {
      console.warn(`[chat] Candidate ${candidate.provider}:${candidate.model} failed:`, err.message);
      failures.push(`${candidate.model}: ${err.message}`);
    }
  }

  console.error('[chat] All models failed sequentially:', failures);
  return res.status(502).json({
    error: 'The study assistant is temporarily unavailable. Please try again.',
    failures,
  });
};

module.exports.config = {
  maxDuration: 60,
};
