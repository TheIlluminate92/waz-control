# Dependencies

This file tracks what WAZ Control actually depends on as development progresses.

## Baseline

Currently developed against:

- Unraid 7.3.x
- x86-64 Unraid host
- modern Chromium-based browser
- Docker enabled for Docker-related modules
- shell access available for installation/recovery

## Project-specific dependencies

These are expected to change as modules are built. A dependency should only be listed here once the code actually relies on it.

### WAZ Health

Initial target:

- Unraid WebUI
- `/proc/uptime`
- JavaScript/CSS injection through the plugin
- Unraid system state sources as implemented during development

### Planned optional integrations

These may provide richer data but should be treated as optional where practical:

- HBAWear
- Unraid API
- Netdata
- NPM Switches
- UPS integration (APC/NUT depending on host)
- Intel GPU telemetry

## Reference hardware

The maintainer's test system includes:

- Dell PowerEdge R360
- Intel Xeon E-2488
- 128 GB DDR5 ECC
- Intel Arc Pro A40
- Dell HBA355i
- LSI/Broadcom 9300-8e
- bonded dual 1 GbE networking
- multiple SSD pools and a large XFS array

Other hardware may require changes.

## Rule for contributors/users

Do not assume that a dependency listed as optional is present. Do not assume sensor paths, network names, GPU names, CPU topology, disk counts, or controller addresses match the reference system.
