# Architecture

Debian Admin Toolkit is split into:

- `bin/deb` — command launcher
- `lib/core.sh` — shared core functions
- `lib/colors.sh` — terminal colors
- `lib/output.sh` — output formatting
- `lib/system.sh` — system information helpers
- `lib/services.sh` — service state helpers
- `modules/*` — executable commands

Runtime configuration is read from `/etc/debian-admin-toolkit/config` when installed.
Local development works directly from the repository checkout.
