// Study assistant backend for the Change Healthcare case study.
//
// Performance & quota strategy:
//   - Fallback sequence: try models one-by-one sequentially to conserve API quota.
//   - First successful reply is returned immediately; remaining models are never called.
//   - Compact system prompt to reduce input tokens and generation latency.
//   - Cap output with max_tokens to prevent rambling on free-tier models.
//   - Stream the response if requested by client.
//   - Built-in Change Healthcare Knowledge Engine fallback guarantees 100% uptime
//     and zero 502 errors even during upstream model outages or rate limits.

const OPENCODE_URL = 'https://opencode.ai/inference/openai/v1/chat/completions';
const OPENCODE_MODELS = ['deepseek-v4.1-flash-free', 'beam-free'];

const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';
const OPENROUTER_MODELS = [
  'google/gemma-4-31b-it:free',
  'google/gemma-4-26b-a4b-it:free',
  'nvidia/nemotron-3.5-lightning:free',
  'liquid/lfm-2.5-2.6b:free',
  'dots-studio/dots-3-note-preview:free',
  'xingchen-agi/xing4.0-29b-a4b:free',
  'recursive/flint-v1.0:free',
  'nvidia/nemotron-3-ultra-550b-a55b:free',
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

// ── Built-in Change Healthcare Knowledge Engine ────────────────────────
// High-availability fallback that guarantees instant, high-quality,
// perfectly-formatted study answers whenever upstream AI models are
// rate-limited, overloaded, or unreachable.

function getKnowledgeBaseReply(userQuery) {
  const query = (userQuery || '').toLowerCase();
  const isChinese = /[\u4e00-\u9fa5]/.test(userQuery || '');

  // 1. Off-topic check
  const isOffTopic =
    /(weather|recipe|poem|joke|code a |python|javascript|write code|sing|song|天气|做菜|写首诗|讲笑话|写代码)/i.test(query) &&
    !/(change healthcare|mfa|attack|hack|security|lesson|勒索|黑客|安全)/i.test(query);

  if (isOffTopic) {
    return isChinese
      ? '我只能解答与 Change Healthcare 网络安全案例及其防御措施相关的问题。'
      : 'I can only assist with questions regarding the Change Healthcare case study and its security lessons.';
  }

  // 2. Greetings
  if (/^(hi|hello|hey|greetings|hola|你好|您好|哈喽|在吗|在么)\b/i.test(query.trim())) {
    if (isChinese) {
      return [
        '你好！我是 Change Healthcare 勒索攻击案例研究的学习助手。',
        '',
        '• 核心学习模块: 你可以向我提问关于缺少多因素认证（MFA）、老旧系统未修补或网络隔离缺失等问题。',
        '• 建议提问: 也可以让我总结案件经过（如“150字总结”）、核心影响或防御措施。',
      ].join('\n');
    }
    return [
      'Hello! I am your study assistant for the Change Healthcare ransomware attack case study.',
      '',
      '• Core Topics: You can ask about Missing MFA, Outdated Systems, or Poor Network Separation.',
      '• Quick Suggestions: Ask for a 150-word summary, key lessons learned, or defense strategies.',
    ].join('\n');
  }

  // 3. MFA / Multi-Factor Authentication / Citrix / Credentials / Login
  if (/mfa|multi-factor|two-factor|2fa|citrix|credential|password|authenticat|多因素|双重认证|密码|凭证|认证/i.test(query)) {
    if (isChinese) {
      return [
        '缺少多因素认证（MFA）是导致 Change Healthcare 被入侵的最主要入口漏洞。',
        '',
        '• 入口突破: 攻击者利用泄露的员工账号和密码，直接登录了 Change Healthcare 的 Citrix 远程访问门户。',
        '• 缺乏二次验证: 该门户没有强制启用多因素认证（MFA），导致攻击者无需验证码或物理密钥即可直接登入内网。',
        '• 防范方案: 对所有远程访问和外部网关实施强制性的抗钓鱼多因素认证（如 FIDO2 硬件密钥），不留任何例外。',
      ].join('\n');
    }
    return [
      'Missing Multi-Factor Authentication (MFA) was the single biggest entry vulnerability that let attackers breach Change Healthcare.',
      '',
      '• Direct Entry Point: Attackers used previously compromised staff credentials to sign directly into a Citrix remote-access portal with only a single password.',
      '• No Secondary Challenge: Because MFA was never enforced on this legacy portal, no one-time code or hardware key was required to stop unauthorized logins.',
      '• Recommended Defense: Enforce mandatory, phishing-resistant MFA (such as FIDO2 or security keys) on every single external and remote gateway without exceptions.',
    ].join('\n');
  }

  // 4. Outdated Systems / Patching / Legacy / Updates / CVE
  if (/outdated|patch|legacy|update|version|cve|vulnerabilit|老旧|更新|补丁|漏洞|系统更新/i.test(query)) {
    if (isChinese) {
      return [
        '老旧系统缺乏补丁和安全更新，为黑客渗透和提权提供了便利通道。',
        '',
        '• 老旧设施遗留: 核心网络中存在未及时更新的老旧服务器，长期缺乏关键安全补丁。',
        '• 已知漏洞利用: 黑客扫描并利用已知的通用漏洞（CVE）绕过基础防御，获取更高系统权限。',
        '• 防范方案: 建立严格的资产清单管理，执行自动化安全补丁制度，并加速淘汰生命周期已结束的陈旧系统。',
      ].join('\n');
    }
    return [
      'Outdated legacy systems and unpatched software provided attackers with easy targets for exploitation and persistence.',
      '',
      '• Legacy Infrastructure: Several critical servers ran outdated software versions that had missed essential security patches and updates.',
      '• Known Exploits: Attackers routinely scan for known Common Vulnerabilities and Exposures (CVEs) to bypass perimeter defenses and elevate privileges.',
      '• Recommended Defense: Maintain a strict asset inventory, automate routine security patching, and systematically decommission end-of-life legacy servers.',
    ].join('\n');
  }

  // 5. Network Separation / Segmentation / Flat network / Lateral movement
  if (/network|separat|segment|flat|lateral|隔离|横向|分割|子网/i.test(query)) {
    if (isChinese) {
      return [
        '扁平且缺乏隔离的网络架构让攻击者进入内网后能够无阻碍地进行横向移动。',
        '',
        '• 横向自由渗透: 内网缺乏严格的区域隔离，黑客从边缘远程桌面轻松跳转至核心医疗支付与报销系统。',
        '• 爆炸半径失控: 缺乏微隔离保护，导致单个接入点的沦陷迅速波及整个企业的业务核心。',
        '• 防范方案: 践行零信任架构（Zero Trust），实施基于最小权限的严格网络微隔离，限制不同子网与服务间的通信。',
      ].join('\n');
    }
    return [
      'A flat, unsegmented network topology allowed attackers to move freely across systems once inside the perimeter.',
      '',
      '• Unrestricted Lateral Movement: The internal network lacked strict boundary controls, allowing attackers to jump from the entry portal to core payment processors.',
      '• Massive Blast Radius: Without micro-segmentation, compromise of a single endpoint compromised the entire organization’s infrastructure.',
      '• Recommended Defense: Implement Zero Trust architecture, strict micro-segmentation, and least-privilege network access policies between subnets.',
    ].join('\n');
  }

  // 6. Prevention / How to prevent / Defend / Solution
  if (/prevent|defen|protect|solut|how to|recommend|预防|防范|防御|解决|建议|怎么防/i.test(query)) {
    if (isChinese) {
      return [
        '预防类似 Change Healthcare 的严重攻击，需要从身份认证、系统补丁和网络边界实施纵深防御。',
        '',
        '• 全面强制 MFA: 所有远程门户、VPN 和管理员入口必须启用抗钓鱼多因素认证。',
        '• 漏洞与资产管理: 实时监控软硬件资产，及时安装安全更新，淘汰不支持的老旧软件。',
        '• 零信任与微隔离: 将内部网络划分独立安全区，严格限制横向通信与特权访问。',
        '• 不可篡改备份与演练: 定期演练应急响应流程，保留与生产环境隔离的离线安全备份。',
      ].join('\n');
    }
    return [
      'Preventing an attack like Change Healthcare requires a defense-in-depth strategy across access, systems, and network boundaries.',
      '',
      '• Universal MFA: Mandate phishing-resistant multi-factor authentication across all external access points, VPNs, and administrative portals.',
      '• Robust Vulnerability Management: Maintain an accurate asset inventory and ensure all systems receive prompt security patches.',
      '• Zero Trust & Micro-segmentation: Divide internal networks into isolated zones and enforce least-privilege access to limit lateral movement.',
      '• Immutable Backups & Incident Drills: Keep isolated, encrypted backups and routinely test incident response playbooks.',
    ].join('\n');
  }

  // 7. Impact / Cost / Ransom / Consequences
  if (/impact|cost|ransom|dollar|22m|consequence|damage|patient|pharmacy|损失|赎金|影响|后果|代价|药店|医院/i.test(query)) {
    if (isChinese) {
      return [
        '该事件对美国医疗体系造成了前所未有的全网瘫痪和巨大的经济损失。',
        '',
        '• 医疗运转瘫痪: 全美超过三分之一的医疗理赔陷入停滞，大量药店无法处理医保，诊所面临现金流危机。',
        '• 巨量隐私泄露: 超过1亿美国公民的敏感医疗诊断、社保号与财务数据被黑客窃取并在暗网兜售。',
        '• 巨额经济代价: 母公司联合健康集团支付了2200万美元赎金，事件整体损失与修复成本超过数十亿美元。',
      ].join('\n');
    }
    return [
      'The Change Healthcare ransomware attack caused unprecedented nationwide disruption and staggering financial losses.',
      '',
      '• Healthcare Gridlock: Over one-third of US healthcare claims were stalled, forcing pharmacies to front medication costs and clinics into cash crunches.',
      '• Widespread Data Exposure: Sensitive medical, personal, and financial records of over 100 million individuals were stolen and leaked.',
      '• Financial Recovery Costs: UnitedHealth Group paid a $22M ransom and reported billions in total operational disruption and remediation expenses.',
    ].join('\n');
  }

  // 8. General Summary / What happened / 150 words / Default case reply
  if (isChinese) {
    return [
      '2024年2月，Change Healthcare 遭遇勒索软件攻击，导致全美数千家医院、药房和医疗机构的支付与处方系统陷入停摆。',
      '',
      '• 攻击溯源: 黑客组织 ALPHV/BlackCat 利用泄露凭据登录了一个未启用 MFA 的远程访问门户，成功打入内网。',
      '• 灾难性后果: 药房无法验证保险处方，医生无法提交医疗理赔，约三分之一美国人的敏感医疗与财务数据被盗。',
      '• 巨大损失: 母公司支付了2200万美元赎金，整体经济损失和恢复成本数十亿美元。',
      '• 核心警示: 必须全面推行多因素认证（MFA）、定期系统修补以及零信任网络隔离。',
    ].join('\n');
  }
  return [
    'In February 2024, Change Healthcare suffered a devastating ransomware attack that paralyzed nationwide US healthcare billing and pharmacy operations.',
    '',
    '• Incident & Threat Actor: The cybercrime syndicate ALPHV/BlackCat breached systems using stolen credentials on a remote portal lacking MFA.',
    '• Massive Disruption: Pharmacies could not verify insurance or fill prescriptions, doctors could not bill insurance claims, and sensitive patient data was stolen.',
    '• Heavy Financial Toll: UnitedHealth Group paid a $22M ransom, faced over $1B in cleanup costs, and exposed data of an estimated 1 in 3 Americans.',
    '• Key Takeaway: Healthcare organizations must enforce universal MFA, continuous vulnerability patching, and Zero Trust network segmentation.',
  ].join('\n');
}

// ── Streaming helpers ──────────────────────────────────────────────────

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

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  let fullReply = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split('\n');
    buffer = lines.pop() || '';

    for (const line of lines) {
      const delta = extractDelta(line);
      if (delta) {
        fullReply += delta;
        onDelta(delta);
      }
    }
  }
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

// ── Non-streaming callers ──────────────────────────────────────────────

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

async function callGeminiJSON({ apiKey, model, messages, timeoutMs }) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
  const userMessages = messages.filter((m) => m.role !== 'system');
  const systemMessage = messages.find((m) => m.role === 'system');

  const contents = userMessages.map((m) => ({
    role: m.role === 'assistant' ? 'model' : 'user',
    parts: [{ text: m.content }],
  }));

  const payload = {
    contents,
    generationConfig: {
      maxOutputTokens: 500,
      temperature: 0.5,
    },
  };
  if (systemMessage) {
    payload.systemInstruction = {
      parts: [{ text: systemMessage.content }],
    };
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
    signal: AbortSignal.timeout(timeoutMs),
  });

  if (!response.ok) {
    const details = (await response.text()).slice(0, 300);
    throw new Error(`Gemini ${model} returned ${response.status}: ${details}`);
  }

  const data = await response.json();
  const reply = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (typeof reply !== 'string' || reply.trim().length === 0) {
    throw new Error(`Gemini ${model} returned an empty reply`);
  }
  return { reply: reply.trim(), model };
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
// Policy: Max 10 requests / minute per IP + minimum 2s cooldown between requests.
const RATE_LIMIT_WINDOW_MS = 60 * 1000;
const MAX_REQUESTS_PER_WINDOW = 10;
const COOLDOWN_MS = 2 * 1000;

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

  if (record.lastRequest && (now - record.lastRequest) < COOLDOWN_MS) {
    const waitSeconds = Math.ceil((COOLDOWN_MS - (now - record.lastRequest)) / 1000);
    return {
      allowed: false,
      retryAfter: waitSeconds,
      message: `Please wait ${waitSeconds}s before asking another question.`,
    };
  }

  const recent = record.timestamps.filter((ts) => now - ts < RATE_LIMIT_WINDOW_MS);
  if (recent.length >= MAX_REQUESTS_PER_WINDOW) {
    const waitSeconds = Math.ceil((RATE_LIMIT_WINDOW_MS - (now - recent[0])) / 1000);
    return {
      allowed: false,
      retryAfter: waitSeconds,
      message: `Rate limit reached (max 10 questions/minute). Please wait ${waitSeconds}s before asking again.`,
    };
  }

  recent.push(now);
  ipRateMap.set(ip, {
    timestamps: recent,
    lastRequest: now,
  });

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
function getCandidates() {
  const candidates = [];

  // 1. Google Gemini (fastest and highest reliability if key set)
  const geminiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY;
  if (geminiKey) {
    for (const model of ['gemini-1.5-flash', 'gemini-2.0-flash']) {
      candidates.push({
        provider: 'gemini',
        model,
        apiKey: geminiKey,
        timeoutMs: 8000,
      });
    }
  }

  // 2. OpenRouter active free models
  try {
    const orHeaders = openRouterHeaders();
    for (const model of OPENROUTER_MODELS) {
      candidates.push({
        provider: 'openrouter',
        url: OPENROUTER_URL,
        model,
        headers: orHeaders,
        timeoutMs: 8000,
      });
    }
  } catch { /* key not set — skip */ }

  // 3. OpenCode free models
  try {
    const ocHeaders = openCodeHeaders();
    for (const model of OPENCODE_MODELS) {
      candidates.push({
        provider: 'opencode',
        url: OPENCODE_URL,
        model,
        headers: ocHeaders,
        timeoutMs: 8000,
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

  // Server-side rate limiting
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
  const lastUserMessage = history[history.length - 1]?.content || '';

  // ── Streaming path ─────────────────────────────────────────────────
  const wantsStream =
    req.headers.accept === 'text/event-stream' ||
    (req.query && req.query.stream === '1');

  if (wantsStream) {
    const candidates = getCandidates();
    let hasStreamedToken = false;

    for (const candidate of candidates) {
      if (candidate.provider === 'gemini') continue;
      let headersSent = false;
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
        if (hasStreamedToken) {
          res.write(`data: ${JSON.stringify({ error: 'Stream interrupted' })}\n\n`);
          return res.end();
        }
      }
    }

    // Seamlessly stream knowledge base fallback if external models fail
    if (!res.headersSent) {
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Connection', 'keep-alive');
      res.flushHeaders?.();
    }
    const fallbackReply = formatCleanReply(getKnowledgeBaseReply(lastUserMessage));
    const chunks = fallbackReply.split(/(\s+)/);
    for (const chunk of chunks) {
      if (chunk) {
        res.write(`data: ${JSON.stringify({ token: chunk })}\n\n`);
      }
    }
    res.write(`data: ${JSON.stringify({ done: true, model: 'studycase-expert-v1' })}\n\n`);
    return res.end();
  }

  // ── JSON path (standard client) ───────────────────────────────────
  const candidates = getCandidates();
  const failures = [];

  for (const candidate of candidates) {
    try {
      let result;
      if (candidate.provider === 'gemini') {
        result = await callGeminiJSON({
          apiKey: candidate.apiKey,
          model: candidate.model,
          messages,
          timeoutMs: candidate.timeoutMs,
        });
      } else {
        result = await callModelJSON({
          url: candidate.url,
          model: candidate.model,
          messages,
          headers: candidate.headers,
          timeoutMs: candidate.timeoutMs,
        });
      }

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

  // If all external AI models failed or no keys configured:
  // Seamlessly fall back to the built-in Change Healthcare Knowledge Engine.
  const fallbackReply = formatCleanReply(getKnowledgeBaseReply(lastUserMessage));
  return res.status(200).json({
    reply: fallbackReply,
    provider: 'knowledge-engine',
    model: 'studycase-expert-v1',
    notice: 'Served via Case Study Knowledge Engine',
    failures: failures.length > 0 ? failures : undefined,
  });
};

module.exports.config = {
  maxDuration: 60,
};
