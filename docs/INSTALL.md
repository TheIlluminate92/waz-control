# Installation

WAZ Control v0.8.0 is a rolling test build for Unraid 7.2+ and is currently tested on Unraid 7.3.2.

## Before installing

- Read the [disclaimer](../DISCLAIMER.md), [dependencies](DEPENDENCIES.md), and [recovery procedure](RECOVERY.md).
- Confirm SSH or local terminal access.
- Back up the Unraid flash configuration.
- Review `waz.dashboard.cfg` defaults for the target hardware.
- Leave the `MD1200-Fan-Controller` Docker container running during installation; the replacement installs disabled and will refuse serial writes while that container is active.

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
php -l /usr/local/emhttp/plugins/waz.dashboard/include/md1200.php
php -l /usr/local/emhttp/plugins/waz.dashboard/include/md1200-controller.php

php /usr/local/emhttp/plugins/waz.dashboard/include/status.php |
jq '{pluginVersion,overall,subsystems}'

cat /var/run/waz.dashboard/md1200.json | jq .
```

## MD1200 migration

The first v0.8 installation copies the legacy Docker settings, Docker template, recent container log, and WAZ controller state to a timestamped folder under:

```text
/mnt/user/Back-Up/MD1200-Fan-Controller
```

The replacement starts with `MD1200_ENABLED="no"`. Review the automatic curve and both SES mappings first, stop the Docker container, then set `MD1200_ENABLED="yes"`. Never run both controllers against the same serial adapters.

To collect the read-only shelf mapping and fan-RPM data, run:

```bash
/usr/local/emhttp/plugins/waz.dashboard/scripts/diagnose-md1200.sh
```

It prints the timestamped destination under `/mnt/user/Back-Up/MD1200-Fan-Controller/diagnostics`. The diagnostic reads cached disk state and SES element status; it does not write to either serial adapter.

Before enabling the host controller, the standalone commissioning test can compare measured fan RPM at 20% and 50% for each shelf. The script refuses to run while the legacy Docker is running or the WAZ controller is enabled, waits ten seconds at each setting, saves raw SES output under the `Back-Up` share, and finishes with both shelves at 50%:

```bash
docker stop MD1200-Fan-Controller
/usr/local/emhttp/plugins/waz.dashboard/scripts/test-md1200-controls.sh
docker start MD1200-Fan-Controller
```

## Updating

Repeat the download, staging, and forced-install commands. Runtime files are replaced in RAM; existing `/boot/config/plugins/waz.dashboard/waz.dashboard.cfg` settings are preserved and new defaults are appended.

## Standalone WAZ Health migration

The unified installer migrates missing Health settings from `/boot/config/plugins/waz.health/waz.health.cfg`, renames `waz.health.plg` to `waz.health.plg.disabled`, and removes the old RAM-backed runtime so two banner loaders cannot coexist. The legacy configuration is retained as a backup.
