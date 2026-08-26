# Installation

WAZ Control v0.7.0 is a rolling test build for Unraid 7.2+ and is currently tested on Unraid 7.3.2.

## Before installing

- Read the [disclaimer](../DISCLAIMER.md), [dependencies](DEPENDENCIES.md), and [recovery procedure](RECOVERY.md).
- Confirm SSH or local terminal access.
- Back up the Unraid flash configuration.
- Review `waz.dashboard.cfg` defaults for the target hardware.

## Download and install

From the Unraid terminal:

```bash
wget -O /boot/config/plugins/waz.dashboard.plg \
  https://raw.githubusercontent.com/TheIlluminate92/waz-control/main/releases/waz.dashboard.plg

cp /boot/config/plugins/waz.dashboard.plg /tmp/waz.dashboard.plg
plugin install /tmp/waz.dashboard.plg forced
```

Reload the entire Unraid WebUI after installation.

## Verify

```bash
php -l /usr/local/emhttp/plugins/waz.dashboard/include/metrics.php
php -l /usr/local/emhttp/plugins/waz.dashboard/include/workloads.php
php -l /usr/local/emhttp/plugins/waz.dashboard/include/storage.php
php -l /usr/local/emhttp/plugins/waz.dashboard/include/status.php

php /usr/local/emhttp/plugins/waz.dashboard/include/status.php |
jq '{pluginVersion,overall,subsystems}'
```

## Updating

Repeat the download, staging, and forced-install commands. Runtime files are replaced in RAM; existing `/boot/config/plugins/waz.dashboard/waz.dashboard.cfg` settings are preserved and new defaults are appended.

## Standalone WAZ Health migration

The unified installer migrates missing Health settings from `/boot/config/plugins/waz.health/waz.health.cfg`, renames `waz.health.plg` to `waz.health.plg.disabled`, and removes the old RAM-backed runtime so two banner loaders cannot coexist. The legacy configuration is retained as a backup.
