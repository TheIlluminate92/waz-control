# Installation

WAZ Control is in early rolling development. Installation steps will be version-specific until the project stabilizes.

## Before installing

- Read `DISCLAIMER.md`.
- Read `docs/RECOVERY.md`.
- Confirm SSH/terminal access to the Unraid host.
- Back up any files/configuration that a test build will touch.
- Verify the documented dependencies for the module/release you are installing.

## Rolling test builds

Installable `.plg` builds will be placed under `releases/` as modules become testable.

Each build should document:

- supported/tested Unraid version
- required plugins/dependencies
- files installed
- uninstall command/path
- known limitations

## Updates

During development, builds may be replaced frequently. Do not assume configuration compatibility between early versions unless the release notes say otherwise.

## Stock Unraid warning

WAZ Control is not currently intended as a stock-compatible or Community Applications package. Follow the dependency notes for each build rather than assuming a one-click install will work everywhere.
