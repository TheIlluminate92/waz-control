# Current rolling release

`waz.dashboard.plg` is WAZ Control v0.8.0, release build `2026.09.01.01`.

It contains the integrated Health banner, Server Status, Workloads, and Storage panels, plus the staged host-native MD1200 fan controller. The fan controller installs disabled and must not be enabled until the legacy Docker container is stopped and both shelf mappings are checked. This is a hardware-specific rolling test build, not a Community Applications release.

See [installation](../docs/INSTALL.md), [dependencies](../docs/DEPENDENCIES.md), and [recovery](../docs/RECOVERY.md) before using it.

For a clean terminal replacement that preserves the existing WAZ configuration, run:

```bash
wget -qO /tmp/install-waz-dashboard.sh \
  https://raw.githubusercontent.com/TheIlluminate92/waz-control/main/releases/install-waz-dashboard.sh
bash /tmp/install-waz-dashboard.sh
```

The installer downloads and verifies the new package before removing the installed plugin. It backs up `waz.dashboard.cfg` outside the directory removed by Unraid, restores it before installation, and retains the backup if installation fails.

The `history/` directory preserves the standalone Health builds that still exist from development. They are provided to show the progression of the project and should not be installed alongside v0.8.0.
