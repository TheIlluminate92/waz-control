# Changelog

## v0.8.0 — 2026-08-31

- Replaced the custom MD1200 Docker controller with a host-native WAZ controller process.
- Added compact MD1200 control to the Health header while shifting subsystem indicators left.
- Auto mode displays separate Top and Bottom average fan RPM from SES telemetry.
- Manual mode offers confirmed 20%, 30%, 40%, and 50% commands for both shelves.
- Preserved independent disk-temperature control per shelf with hysteresis and periodic reassertion.
- Restored a distinct 50% very-hot and sensor-failure step instead of silently remaining at 30%.
- Blocked controller writes while the legacy Docker container is running.
- Added cross-process serial locking and separated command-write status from fan telemetry status.
- Staged fan control disabled by default and added migration backups under the `Back-Up` share.

## v0.7.0 — 2026-08-26

First unified WAZ Control release.

- Combined the Health banner and Dashboard panels under one `waz.dashboard` plugin.
- Added matched Server Status, Workloads, and Storage panels.
- Added live CPU, RAM, GPU, network, rack-power, coolant, flow, UPS, HBA, parity, pool, array, Docker, and process telemetry.
- Added dynamic Docker-folder, selected-container, and selected-pool views.
- Added FolderView Plus, native Docker Organizer, Disk Location, and HBA Viewer integration.
- Added workload and storage attention rows with specific causes.
- Ignored intentionally stopped/on-demand containers when evaluating Workloads attention.
- Matched the integrated Health banner to the dashboard color palette.
- Added standalone WAZ Health configuration migration and recoverable manifest retirement.

The development versions before v0.7.0 were rolling internal test builds and are not published here as supported releases.
