# Changelog

## 1.0.0

- Added unified terminal panel baseline.
- Added shared panel helpers in `lib/panel.sh`.
- Added interactive command picker with `deb menu run`.
- Refreshed CLI help and README for stable baseline.
- Added VPS testing checklist in `docs/TESTING.md`.
- Completed roadmap through v1.0.0.

## 0.9.0

- Added Update module baseline.
- Added shared update helpers in `lib/update.sh`.
- Added update summary, upgradable package list, refresh, dry-run, upgrade, full-upgrade, autoremove, autoclean, and safe workflow.
- Added update log creation, listing, and latest log view.
- Updated README and roadmap for v0.9.0.

## 0.8.0

- Added Logs module baseline.
- Added shared log helpers in `lib/logs.sh`.
- Added journal/syslog backend detection.
- Added recent logs, warning/error logs, service logs, search, kernel logs, boot history, and live follow mode.
- Added configurable default log line count.
- Updated README and roadmap for v0.8.0.

## 0.7.0

- Added Backup module baseline.
- Added shared backup helpers in `lib/backup.sh`.
- Added backup profiles: default, dat, apt, and ssh.
- Added archive listing, latest lookup, verification, contents preview, and pruning.
- Added configurable backup directory and item list.
- Updated README and roadmap for v0.7.0.

## 0.6.0

- Added Doctor module baseline.
- Added shared diagnostics helpers in `lib/doctor.sh`.
- Added system, tool, resource, network, port, and service checks.
- Added per-section diagnostics commands.
- Updated README and roadmap for v0.6.0.

## 0.5.0

- Added Ports module baseline.
- Added shared port helpers in `lib/ports.sh`.
- Added listening port overview with backend detection.
- Added raw socket view, text filtering, and direct port lookup.
- Updated README and roadmap for v0.5.0.

## 0.4.0

- Expanded Services module into an actionable service panel.
- Added service overview, detail view, and journal log view.
- Added start, stop, restart, reload, enable, and disable helpers.
- Added reusable service row and detail helpers in `lib/services.sh`.
- Updated README and roadmap for v0.4.0.

## 0.3.0 polish

- Polished Health Dashboard terminal layout.
- Reduced dashboard width for SSH terminals.
- Added explicit not-installed service state.
- Reused shared service state formatting in health and services modules.

## 0.3.0

- Rebuilt Debian Admin Toolkit baseline.
- Added modular Bash launcher.
- Added Health Dashboard with CPU, RAM, disk, network, and service status.
- Added basic modules for doctor, services, ports, logs, backup, and update.
- Added install and uninstall scripts.
- Added project agent instructions and roadmap.
