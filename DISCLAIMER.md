# Disclaimer

WAZ Control is a personal Unraid WebUI/dashboard customization project.

## Important

**This project is not designed to work on a stock Unraid installation.**

It is developed and tested against one specific Unraid server and may rely on:

- third-party Unraid plugins
- custom sensor paths
- custom dashboard plugins
- hardware-specific sysfs/procfs paths
- specific Docker/container behavior
- specific network interface names
- Unraid WebUI DOM structure that can change between releases

Installing or adapting this project may break parts of the Unraid WebUI, produce incorrect telemetry, or stop working after an Unraid/plugin update.

## No warranty

The software is provided as-is under the MIT License. No guarantee is made that it will work on your system, survive upgrades, coexist with other WebUI modifications, or correctly identify your hardware and health state.

## Back up first

Before installing any build:

1. Keep a copy of the original files/configuration being replaced or extended.
2. Read `docs/RECOVERY.md`.
3. Make sure you have terminal/SSH access to the server.
4. Do not install a test build unless you are comfortable removing it manually if the WebUI becomes unusable.

## Support

No support is guaranteed. This repository is primarily a reference and rolling development project. Issues and pull requests may be used, but response time and compatibility work are not promised.
