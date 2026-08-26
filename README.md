# WAZ Control

Custom Unraid dashboard and WebUI enhancements built around a specific, heavily customized Unraid server.

> [!WARNING]
> **This project will not work correctly on a stock Unraid installation.**
> It depends on specific plugins, system paths, sensors, hardware assumptions, and dashboard behavior documented in this repository. Expect to edit configuration and possibly code for your own system.

## What this is

WAZ Control is a rolling Unraid WebUI/dashboard project focused on dense, useful operator-style telemetry instead of a generic reskin.

The project is developed and tested against the maintainer's personal Unraid server first. Public use is welcome, but compatibility with other systems is not guaranteed.

Current direction includes:

- sticky global health banner
- dynamic CPU topology and pinning verification
- CPU/power averaging
- cooling telemetry
- compact memory and GPU views
- storage controller/HBA views
- network/LACP status
- UPS status
- parity-aware dashboard behavior
- disk-location and array presentation improvements
- cohesive dark theme styling

## Status

**Early development / rolling test build.**

The first module is `WAZ Health`, followed by the rest of the dashboard section-by-section.

## Before installing

Read these first:

- [Disclaimer](DISCLAIMER.md)
- [Dependencies](docs/DEPENDENCIES.md)
- [Installation](docs/INSTALL.md)
- [Recovery](docs/RECOVERY.md)
- [Tips & Notes](docs/TIPS.md)

## Repository layout

```text
waz-control/
├── README.md
├── LICENSE
├── DISCLAIMER.md
├── docs/
├── src/
│   └── health/
├── original/
└── releases/
```

`src/` contains the rolling development modules. `releases/` will contain installable test builds when available. `original/` is reserved for reference/original material where redistribution is appropriate.

## Support model

This is **not** a Community Applications release and no support is guaranteed.

If it works for you, great. If your hardware, plugins, DOM structure, sensors, or Unraid version differ, you may need to adapt it yourself. Pull requests are welcome.

## License

MIT. See [LICENSE](LICENSE).
