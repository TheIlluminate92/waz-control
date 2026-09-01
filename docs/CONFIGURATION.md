# Configuration

Persistent settings live at:

```text
/boot/config/plugins/waz.dashboard/waz.dashboard.cfg
```

The installer preserves existing values during rolling updates.

## General

```ini
DISPLAY_NAME="WAZ-SERVER"
PRIMARY_INTERFACE="bond0"
GPU_CARD="auto"
GPU_RECENT_SECONDS="5"
```

`PRIMARY_INTERFACE` must match the desired physical or bonded interface. `GPU_CARD=auto` selects the first Intel `i915` DRM card; set a specific `cardN` when necessary.

## Health thresholds

```ini
OVERALL_STATE="normal"
OVERALL_MESSAGE=""
ARRAY_STATE="normal"
ARRAY_MESSAGE=""
STORAGE_STATE="normal"
STORAGE_MESSAGE=""
COOLING_STATE="normal"
COOLING_MESSAGE=""
UPS_STATE="normal"
UPS_MESSAGE=""
STORAGE_WARN_PERCENT="95"
STORAGE_FAULT_PERCENT="98"
CPU_WARN_C="60"
CPU_FAULT_C="70"
COOLANT_WARN_C="35"
COOLANT_FAULT_C="40"
FLOW_WARN_LPH="130"
FLOW_FAULT_LPH="120"
THROTTLE_LATCH_SECONDS="300"
UPS_LOAD_WARN_PERCENT="90"
UPS_LOAD_FAULT_PERCENT="100"
```

The coolant collector currently expects a `highflownext` hwmon device with `Coolant temp` and `Flow [dL/h]` labels. Adapt the collector for other hardware.

## MD1200 fan control

The host-native controller is deliberately disabled on first install. It preserves the Docker controller's disk-to-shelf assignments and stable FTDI serial paths.

```ini
MD1200_ENABLED="no"
MD1200_MODE="auto"
MD1200_MANUAL_SPEED="20"
MD1200_POLL_SECONDS="30"
MD1200_REASSERT_SECONDS="900"
MD1200_SENSOR_FAILURE_SPEED="50"
MD1200_HYSTERESIS_C="1"
MD1200_THRESHOLD_WARM_C="35"
MD1200_THRESHOLD_HOT_C="45"
MD1200_THRESHOLD_VERY_HOT_C="50"
MD1200_SPEED_COOL="20"
MD1200_SPEED_WARM="25"
MD1200_SPEED_HOT="30"
MD1200_SPEED_VERY_HOT="50"
MD1200_TOP_SES_DEVICE="/dev/sg18"
MD1200_TOP_SES_ADDRESS="0:0:18:0"
MD1200_BOTTOM_SES_DEVICE="/dev/sg11"
MD1200_BOTTOM_SES_ADDRESS="0:0:11:0"
MD1200_BACKUP_DIR="/mnt/user/Back-Up/MD1200-Fan-Controller"
```

Auto mode chooses a target independently for each shelf from the hottest valid temperature among that shelf's assigned disks. If all assigned disks are spun down it uses the cool speed. If active disks have no valid temperature, it uses the sensor-failure speed. One-degree hysteresis prevents rapid changes around a threshold.

Average RPM requires a working `sg_ses` command. Diagnostics identified the 24 TB Top shelf at SCSI address `0:0:18:0` (`/dev/sg18` during commissioning) and the 14 TB Bottom shelf at `0:0:11:0` (`/dev/sg11`). The controller resolves those addresses back to the current `/dev/sg*` names each time it polls, so ordinary device renumbering does not break telemetry. Each BlueDress command uses a read/write serial session and drains the console reply. A console acknowledgement is reported separately from RPM telemetry and is not treated as proof that a shelf obeyed the command; independent SES RPM remains the proof.
