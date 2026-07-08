# Debian Admin Toolkit

Professional terminal administration toolkit for Debian 12 servers.

Status: Development  
Version: 0.9.0

## Goals

Debian Admin Toolkit is a lightweight Bash toolkit for fast server inspection and routine administration.

Inspired by tools such as `btop`, `fastfetch`, `lazygit`, and `ncdu`, but intentionally kept simple and dependency-free.

## Current commands

```text
deb menu       Command overview
deb health     Health dashboard
deb doctor     Diagnostics and health checks
deb services   Service overview and service actions
deb ports      Listening ports, filtering, and lookup
deb logs       Log browser and filters
deb backup     Backup profiles and archive management
deb update     Safe APT update workflow
```

## Services module

```text
deb services                 Show configured service overview
deb services status nginx    Show service details
deb services logs nginx 50   Show recent logs
deb services restart nginx   Restart service as root
```

Customize the watched service list in `/etc/debian-admin-toolkit/config` with `DAT_SERVICES`.

## Ports module

```text
deb ports              Show listening ports overview
deb ports all          Show raw socket output
deb ports find nginx   Filter ports by text
deb ports port 80      Find listeners on port
```

## Doctor module

```text
deb doctor             Run all diagnostics
deb doctor system      Run system checks
deb doctor tools       Run dependency checks
deb doctor resources   Run CPU/RAM/disk checks
deb doctor services    Run configured service checks
```

## Backup module

```text
deb backup                 Create default backup
deb backup create ssh      Create profile backup
deb backup list            List backup archives
deb backup verify latest   Verify latest archive
deb backup contents latest Show archive contents
deb backup prune 5         Keep newest 5 archives
```

Customize backups in `/etc/debian-admin-toolkit/config` with `DAT_BACKUP_DIR` and `DAT_BACKUP_ITEMS`.

## Logs module

```text
deb logs                 Show recent logs
deb logs errors 80       Show warnings and errors
deb logs service nginx   Show service logs
deb logs find denied     Search recent logs
deb logs kernel          Show kernel logs
deb logs follow          Follow logs live
```

Customize default log output in `/etc/debian-admin-toolkit/config` with `DAT_LOG_LINES`.

## Update module

```text
deb update               Show update summary and upgradable packages
deb update refresh       Run apt-get update
deb update dry-run       Simulate upgrade
deb update upgrade       Run apt-get upgrade -y
deb update safe          update + upgrade + autoremove
deb update logs          List update logs
```

Update logs are stored in `/var/log/debian-admin-toolkit` by default.

## Install

```bash
sudo ./install.sh
```

After installation:

```bash
deb health
```

## Project rules

- Bash only.
- Debian 12 target.
- No unnecessary dependencies.
- Modular code in `lib/` and `modules/`.
- GitHub `develop` is the working branch.
- VPS is a test environment.
