# WAZ Health

First rolling module for WAZ Control.

## Target behavior

A sticky full-width banner directly below the Unraid navigation, available across WebUI pages.

Planned initial contents:

- server name
- overall health state
- ARRAY status
- STORAGE status
- COOLING status
- UPS status
- SERVICES status
- local time
- server uptime

Normal state should remain compact. Attention/fault states may reveal a second line with the reason.

## Development notes

The banner should avoid permanent modification of core Unraid files. Health logic should eventually act as an aggregator for other WAZ modules rather than duplicating all subsystem logic internally.

## Status

Scaffold only. First installable rolling build to follow.
