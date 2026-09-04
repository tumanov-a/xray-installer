#!/bin/bash

# Start or restart Xray with an existing configuration.
# Usage: sudo bash start.sh [config_path]

set -euo pipefail

CONFIG="${1:-/usr/local/etc/xray/config.json}"

if [[ ! -f "$CONFIG" ]]; then
    echo "Config not found: $CONFIG"
    echo "Run: sudo bash setup.sh"
    exit 1
fi

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    exec sudo bash "$0" "$@"
fi

echo "Validating $CONFIG ..."
xray run -test -config "$CONFIG"

echo "Starting xray service ..."
systemctl enable xray
systemctl restart xray
systemctl status xray --no-pager
