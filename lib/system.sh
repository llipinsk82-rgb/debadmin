#!/usr/bin/env bash

get_hostname() {
    hostname
}

get_kernel() {
    uname -r
}

get_os() {

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$PRETTY_NAME"
    else
        echo "Unknown"
    fi

}

get_uptime() {

    uptime -p

}

get_load() {

    awk '{print $1" "$2" "$3}' /proc/loadavg

}

get_cpu_usage() {

    read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat

    total1=$((user+nice+system+idle+iowait+irq+softirq+steal))

    idle1=$((idle+iowait))

    sleep 0.5

    read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat

    total2=$((user+nice+system+idle+iowait+irq+softirq+steal))

    idle2=$((idle+iowait))

    diff_total=$((total2-total1))

    diff_idle=$((idle2-idle1))

    echo $((100*(diff_total-diff_idle)/diff_total))

}

get_ram_percent() {

free |
awk '/Mem:/ { printf "%.0f\n",$3/$2*100 }'

}

get_disk_percent() {

df / |
awk 'NR==2 {gsub("%",""); print $5}'

}
