#!/bin/bash
set -euo pipefail

TOP_PORT="/dev/serial/by-id/usb-FTDI_USB_Serial_Converter_FTE33O9T-if00-port0"
BOTTOM_PORT="/dev/serial/by-id/usb-FTDI_USB_Serial_Converter_FTE32AB2-if00-port0"
TOP_ADDRESS="0:0:18:0"
BOTTOM_ADDRESS="0:0:11:0"
CONFIG_FILE="/boot/config/plugins/waz.dashboard/waz.dashboard.cfg"
BACKUP_ROOT="/mnt/user/Back-Up/MD1200-Fan-Controller/control-tests"
WAIT_SECONDS="10"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this test as root from the Unraid terminal." >&2
  exit 1
fi
if [ ! -d "/mnt/user/Back-Up" ]; then
  echo "Back-Up share is unavailable." >&2
  exit 1
fi
if [ -f "$CONFIG_FILE" ] && grep -Eqi '^MD1200_ENABLED="?(yes|true|1|on)"?$' "$CONFIG_FILE"; then
  echo "The WAZ MD1200 controller is enabled. Disable it before this standalone test." >&2
  exit 1
fi
if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -Fxiq 'MD1200-Fan-Controller'; then
  echo "MD1200-Fan-Controller Docker is running. Stop it before this test." >&2
  exit 1
fi
for REQUIRED in flock sg_ses stty sha1sum; do
  command -v "$REQUIRED" >/dev/null 2>&1 || { echo "$REQUIRED is required." >&2; exit 1; }
done
for PORT in "$TOP_PORT" "$BOTTOM_PORT"; do
  [ -e "$PORT" ] || { echo "Serial adapter missing: $PORT" >&2; exit 1; }
done

resolve_ses() {
  local ADDRESS="$1"
  local GENERIC RESOLVED
  for GENERIC in /sys/class/scsi_generic/sg*; do
    [ -e "$GENERIC/device" ] || continue
    RESOLVED="$(readlink -f "$GENERIC/device")"
    if [ "$(basename "$RESOLVED")" = "$ADDRESS" ]; then
      echo "/dev/$(basename "$GENERIC")"
      return 0
    fi
  done
  return 1
}

TOP_SES="$(resolve_ses "$TOP_ADDRESS")" || { echo "Top MD1200 SES address $TOP_ADDRESS was not found." >&2; exit 1; }
BOTTOM_SES="$(resolve_ses "$BOTTOM_ADDRESS")" || { echo "Bottom MD1200 SES address $BOTTOM_ADDRESS was not found." >&2; exit 1; }

STAMP="$(date +%Y%m%d-%H%M%S)"
RESULT_DIR="$BACKUP_ROOT/$STAMP"
SUMMARY="$RESULT_DIR/summary.csv"
mkdir -p "$RESULT_DIR" /var/run/waz.dashboard
printf 'shelf,command_percent,wait_seconds,fan_count,average_rpm,fan_rpms\n' > "$SUMMARY"
printf 'timestamp,shelf,command_percent\n' > "$RESULT_DIR/commands.csv"

send_speed() {
  local SHELF="$1"
  local PORT="$2"
  local SPEED="$3"
  local HASH LOCK_FILE
  HASH="$(printf '%s' "$PORT" | sha1sum | cut -c1-12)"
  LOCK_FILE="/var/run/waz.dashboard/md1200-${HASH}.lock"
  (
    flock -n 9 || { echo "$SHELF serial adapter is locked by another process." >&2; exit 1; }
    stty -F "$PORT" 38400 raw -echo -crtscts -hupcl cs8 -cstopb -parenb
    exec 8>"$PORT"
    for _ in 1 2 3 4 5; do
      # BlueDress accepts the command when terminated by carriage return only.
      printf 'set_speed %s\r' "$SPEED" >&8
      sleep 0.1
    done
    exec 8>&-
  ) 9>"$LOCK_FILE"
  printf '%s,%s,%s\n' "$(date -Is)" "$SHELF" "$SPEED" >> "$RESULT_DIR/commands.csv"
}

sample_rpm() {
  local SHELF="$1"
  local LABEL="$2"
  local DEVICE="$3"
  local COMMAND_PERCENT="$4"
  local RAW SPEEDS COUNT AVERAGE LIST
  RAW="$RESULT_DIR/${SHELF}-${LABEL}-ses.txt"
  sg_ses -p es "$DEVICE" > "$RAW" 2>&1
  SPEEDS="$(sed -n 's/.*Actual speed=\([0-9][0-9]*\) rpm.*/\1/p' "$RAW" | awk '$1 > 0')"
  COUNT="$(printf '%s\n' "$SPEEDS" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [ "$COUNT" -ne 4 ]; then
    echo "$SHELF reported $COUNT non-zero fan values; expected 4. Results kept in $RAW" >&2
    return 1
  fi
  AVERAGE="$(printf '%s\n' "$SPEEDS" | awk '{sum += $1; count++} END {printf "%.0f", sum / count}')"
  LIST="$(printf '%s\n' "$SPEEDS" | paste -sd';' -)"
  printf '%s,%s,%s,%s,%s,%s\n' "$SHELF" "$COMMAND_PERCENT" "$WAIT_SECONDS" "$COUNT" "$AVERAGE" "$LIST" >> "$SUMMARY"
  echo "$AVERAGE"
}

restore_normal() {
  set +e
  echo "Returning both shelves to their normal 20% resting state..."
  send_speed "top" "$TOP_PORT" 20
  send_speed "bottom" "$BOTTOM_PORT" 20
}
trap restore_normal EXIT
trap 'restore_normal; trap - EXIT; exit 130' INT TERM

echo "Recording baseline RPM..."
TOP_BASELINE="$(sample_rpm top baseline "$TOP_SES" baseline)"
BOTTOM_BASELINE="$(sample_rpm bottom baseline "$BOTTOM_SES" baseline)"

echo "Top MD1200: commanding 20%, waiting ${WAIT_SECONDS}s..."
send_speed top "$TOP_PORT" 20
sleep "$WAIT_SECONDS"
TOP_20="$(sample_rpm top 20-percent "$TOP_SES" 20)"

echo "Top MD1200: commanding 50%, waiting ${WAIT_SECONDS}s..."
send_speed top "$TOP_PORT" 50
sleep "$WAIT_SECONDS"
TOP_50="$(sample_rpm top 50-percent "$TOP_SES" 50)"

echo "Bottom MD1200: commanding 20%, waiting ${WAIT_SECONDS}s..."
send_speed bottom "$BOTTOM_PORT" 20
sleep "$WAIT_SECONDS"
BOTTOM_20="$(sample_rpm bottom 20-percent "$BOTTOM_SES" 20)"

echo "Bottom MD1200: commanding 50%, waiting ${WAIT_SECONDS}s..."
send_speed bottom "$BOTTOM_PORT" 50
sleep "$WAIT_SECONDS"
BOTTOM_50="$(sample_rpm bottom 50-percent "$BOTTOM_SES" 50)"

restore_normal
trap - EXIT INT TERM

classify_response() {
  local LOW="$1"
  local HIGH="$2"
  awk -v low="$LOW" -v high="$HIGH" 'BEGIN { delta=high-low; percent=(low>0 ? delta/low*100 : 0); printf "%s (delta %+d RPM, %.1f%%)\n", (delta>=250 && percent>=10 ? "PASS" : "REVIEW"), delta, percent }'
}

TOP_RESULT="$(classify_response "$TOP_20" "$TOP_50")"
BOTTOM_RESULT="$(classify_response "$BOTTOM_20" "$BOTTOM_50")"
{
  echo "MD1200 control commissioning test"
  echo "Collected: $(date -Is)"
  echo "Top SES: $TOP_ADDRESS -> $TOP_SES"
  echo "Bottom SES: $BOTTOM_ADDRESS -> $BOTTOM_SES"
  echo
  echo "Top baseline: $TOP_BASELINE RPM"
  echo "Top 20%: $TOP_20 RPM"
  echo "Top 50%: $TOP_50 RPM"
  echo "Top response: $TOP_RESULT"
  echo
  echo "Bottom baseline: $BOTTOM_BASELINE RPM"
  echo "Bottom 20%: $BOTTOM_20 RPM"
  echo "Bottom 50%: $BOTTOM_50 RPM"
  echo "Bottom response: $BOTTOM_RESULT"
  echo
  echo "Final direct command: 20% on both shelves"
} | tee "$RESULT_DIR/result.txt"

if command -v zip >/dev/null 2>&1; then
  (cd "$(dirname "$RESULT_DIR")" && zip -qr "${RESULT_DIR}.zip" "$(basename "$RESULT_DIR")")
  echo "Upload this result: ${RESULT_DIR}.zip"
else
  tar -czf "${RESULT_DIR}.tar.gz" -C "$(dirname "$RESULT_DIR")" "$(basename "$RESULT_DIR")"
  echo "Upload this result: ${RESULT_DIR}.tar.gz"
fi

echo "Restart the legacy Docker controller now so it can restore the normal automatic policy."
