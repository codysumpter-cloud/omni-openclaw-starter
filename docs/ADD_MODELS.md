# Add Models Later (Optional)

This starter defaults to local Omni (`omni-core:phase2`) with Ollama.

## Switch local model

```bash
ollama pull qwen2.5:7b
nano ~/.config/omni-agent.env
# set OMNI_MODEL=qwen2.5:7b
systemctl --user restart omni-openclaw.service
```

## Enable paid providers in OpenClaw later

Edit your OpenClaw config/env and add provider keys only if you want fallback:

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GOOGLE_API_KEY` (or `GEMINI_API_KEY`)
- `XAI_API_KEY`

Then restart your OpenClaw gateway:

```bash
openclaw gateway restart
```

Tip: keep local-first as default for zero-cost usage.
