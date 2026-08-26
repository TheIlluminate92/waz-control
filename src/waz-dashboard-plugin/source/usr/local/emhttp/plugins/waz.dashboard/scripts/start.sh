#!/bin/bash

RUNTIME_DIR="/usr/local/emhttp/plugins/waz.dashboard"
STATE_DIR="/var/run/waz.dashboard"
PID_FILE="$STATE_DIR/gpu-sampler.pid"

mkdir -p "$STATE_DIR"

if [ -s "$PID_FILE" ]; then
  OLD_PID="$(cat "$PID_FILE" 2>/dev/null)"
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    exit 0
  fi
  rm -f "$PID_FILE"
fi

nohup /usr/bin/php "$RUNTIME_DIR/include/gpu-sampler.php" >/dev/null 2>&1 &
echo "$!" > "$PID_FILE"
