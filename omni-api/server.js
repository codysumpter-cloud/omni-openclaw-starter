const express = require('express');

const PORT = Number(process.env.OMNI_PORT || 8799);
const OLLAMA_HOST = (process.env.OLLAMA_HOST || 'http://127.0.0.1:11434').replace(/\/$/, '');
const OMNI_MODEL = process.env.OMNI_MODEL || 'omni-core:phase2';

const app = express();
app.use(express.json({ limit: '2mb' }));

async function ollamaChat(messages) {
  const res = await fetch(`${OLLAMA_HOST}/api/chat`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ model: OMNI_MODEL, messages, stream: false })
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`ollama_error_${res.status}: ${text.slice(0, 400)}`);
  }
  return res.json();
}

app.get('/api/omni/health', async (_req, res) => {
  try {
    const ping = await fetch(`${OLLAMA_HOST}/api/tags`);
    const ok = ping.ok;
    return res.json({ ok, api: 'omni', backend: 'local-ollama', model: OMNI_MODEL });
  } catch (e) {
    return res.status(503).json({ ok: false, error: 'ollama_unreachable', message: String(e.message || e) });
  }
});

app.post('/api/omni/chat/completions', async (req, res) => {
  const messages = Array.isArray(req.body?.messages) ? req.body.messages : null;
  if (!messages || messages.length === 0) {
    return res.status(400).json({ ok: false, error: 'bad_request', message: 'messages[] is required' });
  }

  try {
    const out = await ollamaChat(messages);
    const content = out?.message?.content || '';
    return res.json({
      ok: true,
      type: 'chat.completion',
      model: OMNI_MODEL,
      backend: 'local-ollama',
      choices: [{ index: 0, message: { role: 'assistant', content }, finish_reason: 'stop' }],
      usage: out?.eval_count ? { completion_tokens: out.eval_count } : undefined
    });
  } catch (e) {
    return res.status(503).json({ ok: false, error: 'provider_unavailable', message: String(e.message || e) });
  }
});

app.listen(PORT, () => {
  console.log(`omni-api-starter listening on :${PORT}`);
});
