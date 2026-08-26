# Tips & Notes

This document collects practical notes discovered while building and adapting WAZ Control.

## CPU topology

Useful Linux sources include:

- `/sys/devices/system/cpu/cpu*/topology/core_id`
- `/sys/devices/system/cpu/cpu*/topology/physical_package_id`
- `/sys/devices/system/cpu/cpu*/topology/thread_siblings_list`

Do not assume logical CPU numbering implies sibling relationships.

## Docker CPU pinning

Configured Docker cpusets can be inspected with Docker metadata, but configured affinity and effective process/cgroup affinity should be treated separately when verifying pinning.

## IRQ affinity

Useful sources include:

- `/proc/interrupts`
- `/proc/irq/*/smp_affinity_list`
- `/proc/irq/*/effective_affinity_list`

## WebUI development

- Prefer additive CSS/JS over replacing core Unraid files.
- Keep browser developer tools open while testing selectors.
- Expect DOM selectors to break across Unraid updates.
- Keep normal/healthy UI quiet; reserve strong color for attention/fault states.
- Treat intentionally stopped services differently from failed services.

## Performance

Fast visual refresh does not require equally fast expensive data collection. For example, CPU bars can render frequently from a rolling sample while slower hardware/configuration checks update at longer intervals.

More notes will be added as each module is built and tested.
