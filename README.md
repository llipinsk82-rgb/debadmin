# Debian Admin Toolkit

Professional terminal administration toolkit for Debian 12 servers.

Status: Development  
Version: 0.4.0

## Goals

Debian Admin Toolkit is a lightweight Bash toolkit for fast server inspection and routine administration.

Inspired by tools such as `btop`, `fastfetch`, `lazygit`, and `ncdu`, but intentionally kept simple and dependency-free.

## Current commands

```text
deb menu       Command overview
deb health     Health dashboard
deb doctor     Basic diagnostics
deb services   Service overview and service actions
deb ports      Listening ports
deb logs       Recent system logs
deb backup     Basic configuration backup
deb update     APT update helper
```

## Services module

```text
deb services                 Show configured service overview
deb services status nginx    Show service details
deb services logs nginx 50   Show recent logs
deb services restart nginx   Restart service as root
```

Customize the watched service list in `/etc/debian-admin-toolkit/config` with `DAT_SERVICES`.

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
