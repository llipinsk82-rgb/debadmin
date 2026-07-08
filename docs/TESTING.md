# Testing checklist

Run on Debian 12 VPS after every pull and install.

```bash
cd /opt/debian-admin-toolkit
git pull
sudo ./install.sh
```

## Version and panel

```bash
deb --version
deb
deb commands
deb menu help
```

## Core modules

```bash
deb health
deb doctor
deb doctor resources
deb doctor services
```

## Services

```bash
deb services
deb services status nginx
deb services logs nginx 20
```

## WireGuard and WGDashboard

```bash
deb wireguard
deb wireguard config wg0
deb wireguard dashboard
deb wireguard update-check
deb wireguard public-check
deb wireguard backups
deb wireguard cleanup-info
deb wireguard logs 50
```

Root-only restart tests:

```bash
sudo deb wireguard restart-dashboard
sudo deb wireguard restart-tunnel wg0
```

## Ports

```bash
deb ports
deb ports port 80
deb ports port 10086
deb ports find nginx
deb ports summary
```

## Logs

```bash
deb logs summary
deb logs errors 50
deb logs service nginx 30
deb logs kernel 40
```

## Backup

```bash
deb backup profiles
sudo deb backup create default
deb backup list
deb backup verify latest
deb backup contents latest
```

## Update

```bash
deb update
deb update dry-run
sudo deb update refresh
deb update logs
```

## Expected result

- No command should fail with missing library or missing module.
- Non-root commands should work as normal user where possible.
- Root-only actions should show a clear root requirement when run without sudo.
- Dashboard and tables should fit normal SSH terminal width.
- `deb commands` should show all modules and subcommands.
- WGDashboard should show service, port, local HTTP, Python, and version status.
- Public WGDashboard check should show missing when public URL is not configured, or OK/FAIL when configured.
- Backup listing should show available manual backup paths without deleting anything.
