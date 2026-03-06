# Omni OpenClaw Starter (Public Template)

A clean, **brand-neutral** starter repo for anyone new to OpenClaw.

It gives you:
- VM sizing + storage instructions
- One-command install from Cloud Shell
- A customizable agent identity (`AGENT_NAME`)
- OpenClaw + local Omni model flow (no paid model required)
- Optional provider add-ons later (OpenAI/Anthropic/Google/xAI)

---

## 1) Create the VM (Google Cloud)

Recommended baseline:
- Machine: `e2-standard-4` (4 vCPU, 16GB RAM)
- Boot disk: `ubuntu-2404-lts-amd64`, **120GB** balanced persistent disk
- Extra data disk: **200GB** SSD persistent disk (models + media)

From **Cloud Shell**:

```bash
export PROJECT_ID="your-gcp-project-id"
export ZONE="us-central1-a"
export VM_NAME="omni-openclaw"
export BOOT_DISK_GB="120"
export DATA_DISK_GB="200"

curl -fsSL https://raw.githubusercontent.com/codysumpter-cloud/omni-openclaw-starter/main/scripts/create-gcp-vm.sh | bash
```

---

## 2) One-click install on the VM

SSH from Cloud Shell:

```bash
gcloud compute ssh "$VM_NAME" --zone "$ZONE"
```

Inside the VM, run:

```bash
curl -fsSL https://raw.githubusercontent.com/codysumpter-cloud/omni-openclaw-starter/main/scripts/install-openclaw-omni.sh | bash
```

Then configure OpenClaw to use local Omni model (no Anthropic token needed):

```bash
ollama launch openclaw --model omni-core:phase2
```

Then customize your agent name:

```bash
cp ~/omni-openclaw-starter/templates/agent.env.example ~/.config/omni-agent.env
nano ~/.config/omni-agent.env
```

Set:
- `AGENT_NAME=YourAgentName`

Restart service:

```bash
systemctl --user daemon-reload
systemctl --user restart omni-openclaw.service
```

---

## 3) Verify

```bash
openclaw status
curl -fsS http://127.0.0.1:8799/api/omni/health
```

If healthy, your local Omni API is live.

---

## 4) Connect Telegram (quick)

```bash
openclaw configure --section channels
```

In the wizard:
1. Choose **Telegram**
2. Paste your **BotFather token**
3. Add your Telegram numeric user ID to the allowlist
4. Save/apply

Then:

```bash
openclaw gateway restart
openclaw status --deep
```

Tip: if you don't know your Telegram numeric ID, message your bot once, then run:

```bash
openclaw logs --follow
```

(or use any Telegram "get my id" helper bot).

---

## 5) Safe storage defaults (enabled)

This starter now enables automatic storage hygiene:
- Deletes generated files older than **24h**
- Enforces a per-path storage cap of **4096 MB**
- Runs hourly via `systemd --user` timer: `omni-storage-prune.timer`

Config file:

```bash
~/.config/omni-storage.env
```

Default config:

```bash
OMNI_RETENTION_HOURS=24
OMNI_MAX_STORAGE_MB=4096
OMNI_STORAGE_PATHS=$HOME/omni-openclaw-starter/artifacts,/mnt/omni-data/omni-artifacts
```

Useful commands:

```bash
systemctl --user status omni-storage-prune.timer
systemctl --user start omni-storage-prune.service   # run prune now
journalctl --user -u omni-storage-prune.service -n 100 --no-pager
```

---

## 6) Add other models later (optional)

By default this stack runs local-only. To add paid providers later, edit env and restart:

```bash
nano ~/.config/omni-runtime.env
# set OMNI_OPENAI_ENABLED=true + OPENAI_API_KEY=...
# set OMNI_ANTHROPIC_ENABLED=true + ANTHROPIC_API_KEY=...
# set OMNI_GOOGLE_ENABLED=true + GOOGLE_API_KEY=...
# set OMNI_XAI_ENABLED=true + XAI_API_KEY=...

systemctl --user restart omni-openclaw.service
```

See `docs/ADD_MODELS.md`.

If OpenClaw keeps asking for Anthropic/OpenAI on first run, re-pin local model:

```bash
ollama launch openclaw --model omni-core:phase2
openclaw gateway restart
```

---

## Security + privacy notes

- This template contains **no personal identities, tokens, or private endpoints**.
- Every user sets their own `AGENT_NAME`, channels, and API keys.
- Do not commit `.env` files.
