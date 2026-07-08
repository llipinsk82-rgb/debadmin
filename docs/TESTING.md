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

## Ports

```bash
deb ports
deb ports port 80
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
