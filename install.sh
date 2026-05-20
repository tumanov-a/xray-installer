#!/bin/bash

# Xray Reality VPN - Universal One-Liner Installer
# Usage: bash install.sh [DOMAIN]
# Example: bash install.sh example.com

DOMAIN="${1:-speed.cloudflare.com}"
REPO_URL="https://github.com/YOUR_USERNAME/xray_vpn"
TEMP_DIR=$(mktemp -d)

echo "Installing Xray Reality VPN..."
echo "Domain: $DOMAIN"
echo ""

# Download setup script
curl -fsSL "${REPO_URL}/raw/main/setup.sh" -o "$TEMP_DIR/setup.sh"
chmod +x "$TEMP_DIR/setup.sh"

# Run setup
sudo bash "$TEMP_DIR/setup.sh" "$DOMAIN"

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "Installation completed!"
echo "Client config available at: /tmp/client_config.json"
