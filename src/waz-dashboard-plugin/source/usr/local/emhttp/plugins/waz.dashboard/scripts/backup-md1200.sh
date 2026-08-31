#!/bin/bash
set -euo pipefail

CONFIG_FILE="/boot/config/plugins/waz.dashboard/waz.dashboard.cfg"
STATE_FILE="/var/run/waz.dashboard/md1200.json"
DEFAULT_BACKUP_DIR="/mnt/user/Back-Up/MD1200-Fan-Controller"
BACKUP_DIR="$DEFAULT_BACKUP_DIR"

if [ -f "$CONFIG_FILE" ]; then
  CONFIGURED="$(sed -n 's/^MD1200_BACKUP_DIR="\(.*\)"$/\1/p' "$CONFIG_FILE" | head -n1)"
  [ -z "$CONFIGURED" ] || BACKUP_DIR="$CONFIGURED"
fi

if [ ! -d "/mnt/user/Back-Up" ]; then
  echo "Back-Up share is unavailable; MD1200 backup skipped." >&2
  exit 0
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
DESTINATION="$BACKUP_DIR/$STAMP"
mkdir -p "$DESTINATION"

copy_if_present() {
  local SOURCE="$1"
  local TARGET="$2"
  [ ! -f "$SOURCE" ] || cp -p "$SOURCE" "$DESTINATION/$TARGET"
}

copy_if_present "$CONFIG_FILE" "waz.dashboard.cfg"
copy_if_present "$STATE_FILE" "md1200-status.json"
copy_if_present "/mnt/cache/appdata/md1200-fan-controller/config/settings.json" "docker-settings.json"
copy_if_present "/boot/config/plugins/dockerMan/templates-user/my-MD1200-Fan-Controller.xml" "docker-template.xml"

if command -v docker >/dev/null 2>&1 && docker inspect MD1200-Fan-Controller >/dev/null 2>&1; then
  docker inspect MD1200-Fan-Controller > "$DESTINATION/docker-inspect.json"
  docker logs --tail 1000 MD1200-Fan-Controller > "$DESTINATION/docker.log" 2>&1 || true
fi

echo "$DESTINATION"
