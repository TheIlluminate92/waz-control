# Development tips

- Prefer additive `.page`, CSS, JavaScript, and endpoint files over modifying Unraid core files.
- Treat cached Unraid disk data as authoritative when a live device query could wake sleeping disks.
- Keep configured Docker affinity separate from effective cgroup/process affinity.
- Use `/sys/devices/system/cpu/cpu*/topology/thread_siblings_list` rather than assuming CPU-number relationships.
- Compare `/proc/irq/*/smp_affinity_list` with `effective_affinity_list` when checking NIC IRQ placement.
- Find sensors by hwmon device and label rather than hardcoded `hwmonN` numbers, which can change after boot.
- Separate fast browser rendering from slower hardware/configuration polling.
- Treat intentionally stopped and on-demand containers differently from failed autostart services.
- Keep normal UI quiet and reserve strong colors for attention or fault states.
- Always maintain a terminal recovery path while changing WebUI selectors.
