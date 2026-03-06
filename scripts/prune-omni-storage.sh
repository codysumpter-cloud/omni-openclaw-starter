#!/usr/bin/env bash
set -euo pipefail

# Reads config from ~/.config/omni-storage.env
# Defaults are intentionally conservative.

CONF="$HOME/.config/omni-storage.env"
if [ -f "$CONF" ]; then
  # shellcheck disable=SC1090
  source "$CONF"
fi

RETENTION_HOURS="${OMNI_RETENTION_HOURS:-24}"
MAX_STORAGE_MB="${OMNI_MAX_STORAGE_MB:-4096}"
STORAGE_PATHS="${OMNI_STORAGE_PATHS:-$HOME/omni-openclaw-starter/artifacts,/mnt/omni-data/omni-artifacts}"

IFS=',' read -r -a PATHS <<< "$STORAGE_PATHS"

log() { echo "[omni-storage-prune] $*"; }

dir_size_mb() {
  local d="$1"
  du -sm "$d" 2>/dev/null | awk '{print $1}' || echo 0
}

prune_by_age() {
  local d="$1"
  find "$d" -type f -mmin "+$((RETENTION_HOURS*60))" -print -delete 2>/dev/null || true
}

prune_by_size() {
  local d="$1"
  local max="$2"
  local size
  size="$(dir_size_mb "$d")"
  if [ "$size" -le "$max" ]; then
    return 0
  fi

  log "size cap exceeded in $d (${size}MB > ${max}MB), pruning oldest files"
  while [ "$size" -gt "$max" ]; do
    local oldest
    oldest="$(find "$d" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | head -n 1 | cut -d' ' -f2-)"
    [ -z "$oldest" ] && break
    rm -f -- "$oldest" || true
    size="$(dir_size_mb "$d")"
  done
}

for d in "${PATHS[@]}"; do
  d="${d%/}"
  [ -z "$d" ] && continue
  [ -d "$d" ] || continue

  log "pruning path: $d"
  prune_by_age "$d"
  prune_by_size "$d" "$MAX_STORAGE_MB"
done

log "done"
