# Debian Admin Toolkit

Professional administration toolkit for Debian servers.

Status: Development

Version: 0.2.0

## Kolorowy prompt Bash

Skrypt ustawia:

- `root@host` na czerwono,
- zwykłego `user@host` na zielono,
- bieżącą ścieżkę na niebiesko.

Dla roota i wszystkich zwykłych użytkowników:

```bash
sudo bash scripts/setup-shell-colors.sh
```

Tylko dla wskazanych kont:

```bash
sudo bash scripts/setup-shell-colors.sh root franek
```

Zmiana jest zapisywana w pliku `.bashrc` każdego konta i jest idempotentna, więc ponowne uruchomienie skryptu nie dodaje kolejnych kopii wpisu.
