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
