# Add Models Later (Optional)

This starter defaults to local Omni (`omni-core:phase2`) with Ollama.

## Switch local model

```bash
ollama pull qwen2.5:7b
nano ~/.config/omni-agent.env
# set OMNI_MODEL=qwen2.5:7b
systemctl --user restart omni-openclaw.service
```

## Enable optional provider backends later

### Nano Banana 2 (free tier / optional)

Set Omni runtime env in your `prismbot-core` environment (or equivalent runtime env file):

```bash
OMNI_NANOBANANA2_ENABLED=true
OMNI_NANOBANANA2_CHAT_URL=https://<nanobanana2-chat-endpoint>
# optional if service requires auth
OMNI_NANOBANANA2_API_KEY=<token>
OMNI_NANOBANANA2_MODEL=nanobanana-2
```

Then restart Omni runtime and verify:

```bash
openclaw gateway restart
curl -fsS http://127.0.0.1:8799/api/omni/models
```

### Other providers (optional)

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GOOGLE_API_KEY` (or `GEMINI_API_KEY`)
- `XAI_API_KEY`

Tip: keep local-first as default for zero-cost usage.
