#!/bin/bash
set -euo pipefail

CONFIG_FILE="/boot/config/plugins/waz.dashboard/waz.dashboard.cfg"
BACKUP_DIR="/mnt/user/Back-Up/MD1200-Fan-Controller"
if [ -f "$CONFIG_FILE" ]; then
  CONFIGURED="$(sed -n 's/^MD1200_BACKUP_DIR="\(.*\)"$/\1/p' "$CONFIG_FILE" | head -n1)"
  [ -z "$CONFIGURED" ] || BACKUP_DIR="$CONFIGURED"
fi

if [ ! -d "/mnt/user/Back-Up" ]; then
  echo "Back-Up share is unavailable." >&2
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
DESTINATION="$BACKUP_DIR/diagnostics/$STAMP"
mkdir -p "$DESTINATION"

{
  echo "Collected: $(date -Is)"
  echo "Kernel: $(uname -srmo)"
  echo
  echo "Serial adapters:"
  ls -l /dev/serial/by-id 2>&1 || true
  echo
  echo "SCSI generic map:"
  if command -v sg_map >/dev/null 2>&1; then sg_map -i -x 2>&1 || true; else echo "sg_map unavailable"; fi
  echo
  echo "sg_ses:"
  command -v sg_ses 2>&1 || echo "sg_ses unavailable"
} > "$DESTINATION/system.txt"

if [ -f "/var/local/emhttp/disks.ini" ]; then
  cp -p "/var/local/emhttp/disks.ini" "$DESTINATION/disks.ini"
fi

if command -v sg_ses >/dev/null 2>&1; then
  for DEVICE in /dev/sg*; do
    [ -e "$DEVICE" ] || continue
    NAME="$(basename "$DEVICE")"
    if command -v timeout >/dev/null 2>&1; then
      timeout 10 sg_ses -p es "$DEVICE" > "$DESTINATION/${NAME}-element-status.txt" 2>&1 || true
    else
      sg_ses -p es "$DEVICE" > "$DESTINATION/${NAME}-element-status.txt" 2>&1 || true
    fi
  done
fi

echo "$DESTINATION"
