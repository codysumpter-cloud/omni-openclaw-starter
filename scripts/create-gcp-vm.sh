#!/usr/bin/env bash
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${ZONE:=us-central1-a}"
: "${VM_NAME:=omni-openclaw}"
: "${BOOT_DISK_GB:=120}"
: "${DATA_DISK_GB:=200}"

DATA_DISK_NAME="${VM_NAME}-data"

gcloud config set project "$PROJECT_ID" >/dev/null

echo "[1/3] Creating VM: $VM_NAME"
gcloud compute instances create "$VM_NAME" \
  --zone "$ZONE" \
  --machine-type e2-standard-4 \
  --image-family ubuntu-2404-lts-amd64 \
  --image-project ubuntu-os-cloud \
  --boot-disk-size "${BOOT_DISK_GB}GB" \
  --boot-disk-type pd-balanced \
  --scopes cloud-platform

echo "[2/3] Creating data disk: $DATA_DISK_NAME"
gcloud compute disks create "$DATA_DISK_NAME" \
  --zone "$ZONE" \
  --type pd-ssd \
  --size "${DATA_DISK_GB}GB"

echo "[3/3] Attaching data disk"
gcloud compute instances attach-disk "$VM_NAME" \
  --disk "$DATA_DISK_NAME" \
  --zone "$ZONE"

echo "Done. SSH with: gcloud compute ssh $VM_NAME --zone $ZONE"
