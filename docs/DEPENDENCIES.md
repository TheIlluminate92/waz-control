# Dependencies

This file tracks what WAZ Control actually depends on as development progresses.

## Baseline

Currently developed against:

- Unraid 7.3.x on x86-64
- Unraid WebUI / emhttp plugin system
- a modern browser with JavaScript enabled
- shell access for installation and recovery

The current WAZ Health plugin declares `min="6.12.0"`, but development/testing is being done on Unraid 7.3.x. Do not interpret the declaration as a compatibility guarantee for every 6.12+ release.

## WAZ Health v0.3.0 / plugin build 2026.08.25.004

The uploaded rolling build was reviewed directly. It does **not** depend on Home Assistant, Unraid API, NPM Switches, Netdata, HBAWear, or Docker for its current health banner.

### Required host interfaces

WAZ Health currently reads directly from standard Linux/Unraid runtime sources:

- `/proc/uptime` for server uptime
- `/var/local/emhttp/var.ini` for array state, missing/disabled/invalid disks, and parity error count
- `/var/local/emhttp/disks.ini` for disk/pool capacity usage
- `/sys/class/hwmon/` for CPU and supported cooling sensor telemetry
- `/sys/devices/system/cpu/cpu0/thermal_throttle/` for thermal-throttle counters when exposed

It installs runtime files under:

- `/usr/local/emhttp/plugins/waz.health/`

and persistent configuration under:

- `/boot/config/plugins/waz.health/`

### Cooling sensor assumptions

CPU temperature detection currently expects Linux `coretemp` hwmon data and looks for labels such as `Package id 0` or `CPU Temp`.

The custom liquid-cooling collector currently expects an hwmon device named:

- `highflownext`

with labels:

- `Coolant temp`
- `Flow [dL/h]`

The plugin converts the flow input from dL/h to L/h. Systems without these exact hwmon names/labels will simply lack those coolant/flow metrics unless the collector is adapted.

This is one of the major reasons the repository is explicitly **not stock-compatible**.

### UPS support

UPS health is optional at runtime. The plugin auto-detects either:

- NUT via `upsc`, or
- apcupsd via `apcaccess`

If neither command exists, UPS metrics are reported as unavailable rather than causing the plugin to fail.

### Browser/WebUI behavior

The banner is injected through `WazHealthBanner.page`, with local CSS and JavaScript served from the plugin directory. It refreshes the health JSON endpoint every five seconds and updates browser-local time once per minute.

The banner expects common Unraid WebUI elements such as `#menu` and `#displaybox`; changes to Unraid's DOM can therefore break placement or sticky behavior.

## Current configurable thresholds

The rolling build creates `/boot/config/plugins/waz.health/waz.health.cfg` on first install. Current defaults are:

- storage warning: 95%
- storage fault: 98%
- CPU warning: 60°C
- CPU fault: 70°C
- coolant warning: 35°C
- coolant fault: 40°C
- flow warning: 130 L/h
- flow fault: 120 L/h
- throttle latch: 300 seconds
- UPS load warning: 90%
- UPS load fault: 100%

These defaults are specific to the reference setup and should be reviewed before using the project elsewhere.

## Planned optional integrations

Later WAZ Control modules may use or integrate with:

- HBAWear
- Unraid API
- Netdata
- NPM Switches
- Intel GPU telemetry

Those are **not current WAZ Health requirements**.

## Reference hardware

The maintainer's test system includes:

- Dell PowerEdge R360
- Intel Xeon E-2488
- 128 GB DDR5 ECC
- Intel Arc Pro A40
- Dell HBA355i
- LSI/Broadcom 9300-8e
- bonded dual 1 GbE networking
- Aqua Computer high flow NEXT cooling telemetry
- multiple SSD pools and a large XFS array

Other hardware may require changes.

## Rule for users/contributors

Do not assume sensor paths, sensor labels, network names, GPU names, CPU topology, disk counts, controller addresses, or third-party plugins match the reference system. Every new dependency should be documented here when it is actually introduced.
