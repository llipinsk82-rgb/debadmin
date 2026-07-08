#!/usr/bin/env bash

header() {
    clear
    echo
    echo -e "\033[1;36m╔════════════════════════════════════════════════════════════╗\033[0m"
    printf "\033[1;36m║ %-58s ║\033[0m\n" "DebAdmin $(cat "$DAT_HOME/VERSION")"
    echo -e "\033[1;36m╚════════════════════════════════════════════════════════════╝\033[0m"
    echo
}

line() {
    echo -e "\033[1;30m────────────────────────────────────────────────────────────\033[0m"
}

ok() {
    printf "\033[1;32m●\033[0m %s\n" "$1"
}

warn() {
    printf "\033[1;33m●\033[0m %s\n" "$1"
}

fail() {
    printf "\033[1;31m○\033[0m %s\n" "$1"
}

info() {
    printf "\033[1;36m➜\033[0m %s\n" "$1"
}

bar() {
    local percent=$1
    local width=30
    local filled=$((percent * width / 100))

    printf "["

    for ((i=0;i<filled;i++)); do
        printf "█"
    done

    for ((i=filled;i<width;i++)); do
        printf "░"
    done

    printf "] %3d%%" "$percent"
}
