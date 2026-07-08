#!/usr/bin/env bash

service_ok() {

systemctl is-active --quiet "$1"

}
