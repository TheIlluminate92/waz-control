# Current rolling release

`waz.dashboard.plg` is WAZ Control v0.8.0, release build `2026.08.31.12`.

It contains the integrated Health banner, Server Status, Workloads, and Storage panels, plus the staged host-native MD1200 fan controller. The fan controller installs disabled and must not be enabled until the legacy Docker container is stopped and both shelf mappings are checked. This is a hardware-specific rolling test build, not a Community Applications release.

See [installation](../docs/INSTALL.md), [dependencies](../docs/DEPENDENCIES.md), and [recovery](../docs/RECOVERY.md) before using it.

The `history/` directory preserves the standalone Health builds that still exist from development. They are provided to show the progression of the project and should not be installed alongside v0.8.0.
