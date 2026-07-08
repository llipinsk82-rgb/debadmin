#!/usr/bin/env bash

header() {

echo

echo -e "${CYAN}═══════════════════════════════════════════════════════"

echo -e " Debian Admin Toolkit"

echo -e "═══════════════════════════════════════════════════════${RESET}"

echo

}

ok() {

echo -e "${GREEN}✔${RESET} $1"

}

warn() {

echo -e "${YELLOW}⚠${RESET} $1"

}

fail() {

echo -e "${RED}✘${RESET} $1"

}

info() {

echo -e "${CYAN}➜${RESET} $1"

}
