# Changelog

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
