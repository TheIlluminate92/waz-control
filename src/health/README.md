# WAZ Health

First rolling module for WAZ Control.

## Current rolling build

- Plugin build: `2026.08.25.004`
- Internal module version: `WAZ Health v0.3.0`
- Minimum declared Unraid version: `6.12.0`
- Primary development/test target: Unraid 7.3.x

## Current behavior

The uploaded plugin currently implements:

- sticky full-width banner below the Unraid navigation
- `WAZ-SERVER` display label from persistent config
- automatically derived overall health state
- ARRAY status
- STORAGE status
- COOLING status
- UPS status
- browser-local time
- compact server uptime from `/proc/uptime`
- five-second health refresh without a full page reload
- automatic second-row expansion for active attention/fault messages
- JSON status endpoint for later WAZ modules
- browser API exposed as `window.WAZHealth`

`SERVICES` is intentionally not present in v0.3.0; the plugin changelog states that it was removed until its future visual/configuration behavior is designed.

## Data sources

The module reads directly from Unraid/Linux runtime data rather than Home Assistant or the Unraid API plugin:

- `/var/local/emhttp/var.ini`
- `/var/local/emhttp/disks.ini`
- `/proc/uptime`
- `/sys/class/hwmon/`
- `/sys/devices/system/cpu/cpu0/thermal_throttle/`
- NUT `upsc` when available
- apcupsd `apcaccess` when available

See [Dependencies](../../docs/DEPENDENCIES.md) for the exact assumptions and sensor labels.

## Persistent configuration

First install creates:

`/boot/config/plugins/waz.health/waz.health.cfg`

Rolling updates preserve that file and add newly introduced defaults when missing.

Runtime files are rebuilt under:

`/usr/local/emhttp/plugins/waz.health/`

## Current architecture

The plugin is self-contained as an inline Unraid `.plg` manifest. The manifest writes:

- `assets/css/banner.css`
- `assets/js/banner.js`
- `include/health.php`
- `include/status.php`
- `WazHealthBanner.page`

The long-term repository layout may split those files into normal source files and generate/package the `.plg` for releases. The uploaded `.plg` remains the source of truth for the current test build until that split is completed.

## Known hardware-specific behavior

The current cooling collector expects:

- CPU hwmon device `coretemp`
- Aqua Computer high flow NEXT hwmon device `highflownext`
- `Coolant temp` label
- `Flow [dL/h]` label

This is intentionally documented rather than hidden: WAZ Control is a custom build and is not expected to work stock on arbitrary Unraid systems.

## Next step

Preserve this working rolling build, then split the inline plugin contents into maintainable source files before adding the next WAZ Control module.
