# AGENTS.md

## Project

Debian Admin Toolkit is a lightweight terminal administration toolkit for Debian 12.

## Repository

- Repo: `llipinsk82-rgb/debadmin`
- Working branch: `develop`
- Do not work directly on `main`.

## Workflow

When the user writes `GO`, it means:

- accept the task,
- implement changes,
- commit/push to `develop`,
- return only the commit hash, changed files, and short changelog.

Do not paste code into chat when GitHub write access is available.

## Architecture

- `bin/` contains launchers.
- `lib/` contains reusable Bash libraries.
- `modules/` contains executable user commands.
- `docs/` contains project documentation.
- Keep modules small and focused.
- Do not hardcode project paths when they can be derived or configured.
- Prefer environment/config overrides.

## Roadmap

- v0.3.0: Health Dashboard
- v0.4.0: Services
- v0.5.0: Ports
- v0.6.0: Doctor
- v0.7.0: Backup
- v0.8.0: Logs
- v0.9.0: Update
- v1.0.0: Full terminal administration panel
