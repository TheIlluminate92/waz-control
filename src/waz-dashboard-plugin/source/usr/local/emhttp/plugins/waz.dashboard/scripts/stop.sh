#!/bin/bash

STATE_DIR="/var/run/waz.dashboard"
PID_FILE="$STATE_DIR/gpu-sampler.pid"

if [ -s "$PID_FILE" ]; then
  PID="$(cat "$PID_FILE" 2>/dev/null)"
  if [ -n "$PID" ] && [ -r "/proc/$PID/cmdline" ] && tr '\0' ' ' < "/proc/$PID/cmdline" | grep -q '/waz.dashboard/include/gpu-sampler.php'; then
    kill "$PID" 2>/dev/null || true
  fi
fi

rm -f "$PID_FILE" "$STATE_DIR/gpu.json"
