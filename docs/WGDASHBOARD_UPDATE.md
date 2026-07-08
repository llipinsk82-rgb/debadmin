# WGDashboard maintenance procedure

This document records the safe manual procedure used for WGDashboard when the built-in project script is not safe for the local install layout.

Target layout used on the VPS:

```text
/root/WGDashboard
/root/WGDashboard/src
/root/WGDashboard/src/venv
/etc/systemd/system/wg-dashboard.service
/etc/wireguard
```

## Current stable target

```text
WGDashboard: v4.3.3
Python venv: Python 3.12.x
System python3: keep Debian default unchanged
Service: wg-dashboard.service
Local URL: http://127.0.0.1:10086/
```

Do not replace `/usr/bin/python3`. WGDashboard must use its own virtual environment.

## Preflight

```bash
systemctl status wg-dashboard --no-pager -l
curl -I http://127.0.0.1:10086/
python3 --version
python3.12 --version
/root/WGDashboard/src/venv/bin/python3 --version
```

## Backups

```bash
ts=$(date +%F-%H%M)

systemctl stop wg-dashboard

cp -a /root/WGDashboard /root/WGDashboard.backup.$ts
cp -a /etc/wireguard /root/wireguard.backup.$ts
cp -a /etc/systemd/system/wg-dashboard.service /root/wg-dashboard.service.backup.$ts
```

Keep these backups for at least 1-2 days after a successful change.

## Files to preserve

Inside `/root/WGDashboard/src` preserve:

```text
db/
wg-dashboard.ini
ssl-tls.ini
wg-dashboard-oidc-providers.json
log/
download/
attachments/
```

## Manual release staging

```bash
ts=$(date +%F-%H%M)

rm -rf /root/WGDashboard.v4.3.3.stage /tmp/wgd433.tar.gz

curl -L -o /tmp/wgd433.tar.gz \
  https://github.com/WGDashboard/WGDashboard/archive/refs/tags/v4.3.3.tar.gz

mkdir -p /root/WGDashboard.v4.3.3.stage
tar -xzf /tmp/wgd433.tar.gz -C /root/WGDashboard.v4.3.3.stage --strip-components=1

test -f /root/WGDashboard.v4.3.3.stage/src/wgd.sh || exit 1
```

## Copy runtime data into staged tree

```bash
rm -rf /root/WGDashboard.v4.3.3.stage/src/db
cp -a /root/WGDashboard/src/db /root/WGDashboard.v4.3.3.stage/src/db

cp -a /root/WGDashboard/src/wg-dashboard.ini /root/WGDashboard.v4.3.3.stage/src/ 2>/dev/null || true
cp -a /root/WGDashboard/src/ssl-tls.ini /root/WGDashboard.v4.3.3.stage/src/ 2>/dev/null || true
cp -a /root/WGDashboard/src/wg-dashboard-oidc-providers.json /root/WGDashboard.v4.3.3.stage/src/ 2>/dev/null || true

cp -a /root/WGDashboard/src/log /root/WGDashboard.v4.3.3.stage/src/log 2>/dev/null || true
cp -a /root/WGDashboard/src/download /root/WGDashboard.v4.3.3.stage/src/download 2>/dev/null || true
cp -a /root/WGDashboard/src/attachments /root/WGDashboard.v4.3.3.stage/src/attachments 2>/dev/null || true
```

## Move into production and rebuild venv in final path

Build the venv after the staged tree has been moved to `/root/WGDashboard`; otherwise scripts such as `venv/bin/gunicorn` may contain a stale shebang path.

```bash
systemctl stop wg-dashboard

mv /root/WGDashboard /root/WGDashboard.old-v4.3.2.$ts
mv /root/WGDashboard.v4.3.3.stage /root/WGDashboard
chmod +x /root/WGDashboard/src/wgd.sh

cd /root/WGDashboard/src
rm -rf venv

python3.12 -m venv venv
./venv/bin/python3 --version
./venv/bin/python3 -m pip install --upgrade pip setuptools wheel
./venv/bin/python3 -m pip install -r requirements.txt
./venv/bin/python3 -m pip install gunicorn

head -1 ./venv/bin/gunicorn
```

The first line of `venv/bin/gunicorn` should point to `/root/WGDashboard/src/venv/bin/python3`.

## Dependency sanity

```bash
cd /root/WGDashboard/src

./venv/bin/python3 -m pip install --upgrade \
  "requests>=2.32,<3" \
  "urllib3<3" \
  "charset-normalizer<4" \
  "chardet<6"

./venv/bin/python3 -m pip check
```

Expected:

```text
No broken requirements found.
```

## Start and verify

```bash
systemctl daemon-reload
systemctl start wg-dashboard
sleep 5

systemctl status wg-dashboard --no-pager -l
curl -I http://127.0.0.1:10086/
```

Expected:

```text
Active: active (running)
HTTP/1.1 200 OK
```

## DebAdmin verification

```bash
sudo sed -i 's/^DAT_WG_DASHBOARD_VERSION=.*/DAT_WG_DASHBOARD_VERSION="v4.3.3"/' /etc/debian-admin-toolkit/config

cd /opt/debian-admin-toolkit
deb wireguard
deb wireguard logs 50
deb wireguard backups
```

Expected:

```text
Local ver      v4.3.3
Latest ver     v4.3.3
Update                       [ OK ]
Python req                   [ OK ]
Port check                   [ OK ]
HTTP check                   [ OK ]
```

## Rollback

```bash
systemctl stop wg-dashboard

rm -rf /root/WGDashboard
mv /root/WGDashboard.old-v4.3.2.$ts /root/WGDashboard

systemctl start wg-dashboard
curl -I http://127.0.0.1:10086/
```

## Cleanup

Do not delete backups immediately. After 1-2 days of stable service, review:

```bash
deb wireguard backups
deb wireguard cleanup-info
```

Delete backups manually only after confirming the active panel, WireGuard tunnel, and database are healthy.
