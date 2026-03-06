#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$HOME/omni-openclaw-starter"
MOUNT_POINT="/mnt/omni-data"
DEVICE="/dev/disk/by-id/google-$(hostname)-data"

echo "==> Installing base packages"
sudo apt-get update -y
sudo apt-get install -y curl git ca-certificates gnupg lsb-release jq build-essential

if ! command -v node >/dev/null 2>&1; then
  echo "==> Installing Node.js 22"
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

if ! command -v openclaw >/dev/null 2>&1; then
  echo "==> Installing OpenClaw CLI"
  curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard
fi

if ! command -v ollama >/dev/null 2>&1; then
  echo "==> Installing Ollama"
  curl -fsSL https://ollama.com/install.sh | sh
fi

echo "==> Ensuring data disk mount"
if [ -b "$DEVICE" ]; then
  if ! lsblk -f "$DEVICE" | grep -q ext4; then
    sudo mkfs.ext4 -F "$DEVICE"
  fi
  sudo mkdir -p "$MOUNT_POINT"
  UUID="$(sudo blkid -s UUID -o value "$DEVICE")"
  if ! grep -q "$UUID" /etc/fstab; then
    echo "UUID=$UUID $MOUNT_POINT ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab >/dev/null
  fi
  sudo mount -a
  sudo chown -R "$USER":"$USER" "$MOUNT_POINT"
else
  echo "WARN: data disk $DEVICE not found. Continuing without extra mount."
fi

if [ ! -d "$REPO_DIR" ]; then
  echo "==> Cloning starter repo"
  git clone https://github.com/codysumpter-cloud/omni-openclaw-starter.git "$REPO_DIR"
fi

cd "$REPO_DIR/omni-api"
echo "==> Installing OmniAPI starter dependencies"
npm install

echo "==> Pulling base model"
ollama pull llama3.2:3b

echo "==> Building omni-core:phase2"
ollama create omni-core:phase2 -f "$REPO_DIR/omni-api/Modelfile.phase2"

mkdir -p "$HOME/.config"
if [ ! -f "$HOME/.config/omni-agent.env" ]; then
  cp "$REPO_DIR/templates/agent.env.example" "$HOME/.config/omni-agent.env"
fi

mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/omni-openclaw.service" <<'UNIT'
[Unit]
Description=Omni OpenClaw Starter API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
EnvironmentFile=%h/.config/omni-agent.env
WorkingDirectory=%h/omni-openclaw-starter/omni-api
ExecStart=/usr/bin/env node %h/omni-openclaw-starter/omni-api/server.js
Restart=always
RestartSec=2

[Install]
WantedBy=default.target
UNIT

systemctl --user daemon-reload
systemctl --user enable --now omni-openclaw.service

cat <<'DONE'

✅ Install complete.

Next:
1) Configure OpenClaw to local model only (no Anthropic/OpenAI required):
   ollama launch openclaw --model omni-core:phase2
2) Set your agent identity: nano ~/.config/omni-agent.env (AGENT_NAME)
3) Verify:
   - openclaw status
   - curl -fsS http://127.0.0.1:8799/api/omni/health

DONE
