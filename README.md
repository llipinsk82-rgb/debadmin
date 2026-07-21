# Debian Admin Toolkit

Professional administration toolkit for Debian servers.

Status: Development

Version: 0.2.0

## Instalacja

```bash
git clone https://github.com/llipinsk82-rgb/debadmin.git
cd debadmin
git checkout feature/user-shell-colors
sudo bash install.sh
```

Instalator:

- kopiuje narzędzie do `/opt/debian-admin-toolkit`,
- tworzy konfigurację w `/etc/debian-admin-toolkit/config`,
- dodaje polecenie `deb` w `/usr/local/bin`,
- automatycznie ustawia kolorowy prompt Bash dla roota i zwykłych użytkowników.

Po instalacji uruchom:

```bash
deb
```

Kolory pojawią się po ponownym zalogowaniu albo po wykonaniu:

```bash
source ~/.bashrc
```

## Kolorowy prompt Bash

Ustawienia domyślne:

- `root@host` — czerwony,
- zwykły `user@host` — zielony,
- bieżąca ścieżka — niebieska.

Kolory są ustawiane automatycznie przez `install.sh` dla roota i użytkowników z UID od 1000.

Skrypt można też uruchomić osobno:

```bash
sudo bash scripts/setup-shell-colors.sh
```

Tylko dla wskazanych kont:

```bash
sudo bash scripts/setup-shell-colors.sh root franek
```

Zmiana jest zapisywana w pliku `.bashrc` każdego konta i jest idempotentna, więc ponowne uruchomienie nie dodaje kolejnych kopii wpisu.
