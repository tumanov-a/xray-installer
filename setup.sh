#!/bin/bash

# Xray Reality VPN Setup Script
# This script installs Xray and generates all necessary configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DOMAIN="${1:-speed.cloudflare.com}"
NUM_SHORTIDS="${2:-2}"
CONFIG_DIR="/usr/local/etc/xray"
LOG_FILE="/tmp/xray_setup.log"

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Xray Reality VPN Setup${NC}"
echo -e "${GREEN}======================================${NC}"
echo "Domain: $DOMAIN"
echo "Number of ShortIds: $NUM_SHORTIDS"
echo "Config Directory: $CONFIG_DIR"
echo ""

# Function to log output
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Step 1: Install Xray
log_info "Step 1: Installing Xray..."
bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
log_info "Xray installed successfully"

# Step 2: Generate cryptographic keys
log_info "Step 2: Generating cryptographic keys..."
KEY_OUTPUT=$(xray x25519)
PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep "Private key:" | awk '{print $NF}')
PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep "Public key:" | awk '{print $NF}')
log_info "Private Key: $PRIVATE_KEY"
log_info "Public Key: $PUBLIC_KEY"

# Step 3: Generate UUID
log_info "Step 3: Generating UUID..."
UUID=$(cat /proc/sys/kernel/random/uuid)
log_info "UUID: $UUID"

# Step 4: Generate shortIds (multiple)
log_info "Step 4: Generating $NUM_SHORTIDS shortIds..."
SHORTID_LIST=()
for i in $(seq 1 $NUM_SHORTIDS); do
    SHORTID=$(openssl rand -hex 8)
    SHORTID_LIST+=("$SHORTID")
    log_info "ShortId $i: $SHORTID"
done

# Create JSON array of shortIds for template substitution
SHORTIDS_JSON=$(printf ',"%s"' "${SHORTID_LIST[@]}")
SHORTIDS_JSON="[\"${SHORTIDS_JSON:1}\"" || SHORTIDS_JSON="[\"${SHORTIDS_JSON}\"]"

# For template substitution (properly formatted JSON array)
SHORTIDS_JSON_ARRAY=$(printf '%s\n' "${SHORTID_LIST[@]}" | jq -R . | jq -s .)

# Use first shortId as primary
SHORTID1="${SHORTID_LIST[0]}"
log_info "Primary ShortId for client: $SHORTID1"

# Step 5: Create server configuration
log_info "Step 5: Creating server configuration..."
mkdir -p "$CONFIG_DIR"

# Read template and replace variables
CONFIG_CONTENT=$(cat config.json.template)

# Create JSON array of shortIds for substitution
SHORTIDS_JSON="["
for i in "${!SHORTID_LIST[@]}"; do
    if [ $i -gt 0 ]; then
        SHORTIDS_JSON="${SHORTIDS_JSON},"
    fi
    SHORTIDS_JSON="${SHORTIDS_JSON}\"${SHORTID_LIST[$i]}\""
done
SHORTIDS_JSON="${SHORTIDS_JSON}]"

# Replace all variables in template
CONFIG_CONTENT="${CONFIG_CONTENT//\{\{DOMAIN\}\}/$DOMAIN}"
CONFIG_CONTENT="${CONFIG_CONTENT//\{\{PRIVATE_KEY\}\}/$PRIVATE_KEY}"
CONFIG_CONTENT="${CONFIG_CONTENT//\{\{SHORTIDS_JSON\}\}/$SHORTIDS_JSON}"

echo "$CONFIG_CONTENT" > "$CONFIG_DIR/config.json"

log_info "Server configuration created"

# Step 6: Enable firewall rules
log_info "Step 6: Configuring firewall..."
ufw allow 443/tcp || log_warn "UFW not available or already configured"

# Step 7: Restart and enable Xray
log_info "Step 7: Starting Xray service..."
systemctl restart xray
systemctl enable xray
log_info "Xray service started and enabled"

# Step 8: Output client configuration
log_info "Step 8: Generating client configuration..."

# Get server IP from first argument or local IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Read client template
CLIENT_CONTENT=$(cat client_config.json.template)

# Replace variables in client template
CLIENT_CONTENT="${CLIENT_CONTENT//\{\{SERVER_IP\}\}/$SERVER_IP}"
CLIENT_CONTENT="${CLIENT_CONTENT//\{\{UUID\}\}/$UUID}"
CLIENT_CONTENT="${CLIENT_CONTENT//\{\{DOMAIN\}\}/$DOMAIN}"
CLIENT_CONTENT="${CLIENT_CONTENT//\{\{PUBLIC_KEY\}\}/$PUBLIC_KEY}"
CLIENT_CONTENT="${CLIENT_CONTENT//\{\{SHORTID_1\}\}/$SHORTID1}"

echo "$CLIENT_CONTENT" > /tmp/client_config.json

log_info "Client configuration created"

# Display results
log_info ""
log_info "=========================================="
log_info "Installation completed successfully!"
log_info "=========================================="
log_info ""
log_info "Server Configuration:"
log_info "  Domain: $DOMAIN"
log_info "  Private Key: $PRIVATE_KEY"
log_info "  Public Key: $PUBLIC_KEY"
log_info "  UUID: $UUID"
log_info "  Number of ShortIds: ${#SHORTID_LIST[@]}"
for i in "${!SHORTID_LIST[@]}"; do
    log_info "  ShortId $((i+1)): ${SHORTID_LIST[$i]}"
done
log_info ""
log_info "Client Configuration saved to: /tmp/client_config.json"
log_info "Server Configuration saved to: $CONFIG_DIR/config.json"
log_info ""
log_info "=========================================="
log_info "VLESS URI for Client Applications:"
log_info "=========================================="

# Generate VLESS URI
VLESS_URI="vless://${UUID}@${SERVER_IP}:443?type=tcp&security=reality&pbk=${PUBLIC_KEY}&fp=chrome&sni=${DOMAIN}&sid=${SHORTID1}&encryption=none#reality"

echo -e "${BLUE}${VLESS_URI}${NC}"
echo ""
log_info "Copy this URI and paste it into your Xray client application"
log_info ""
log_info "Available ShortIds for additional clients:"
for i in "${!SHORTID_LIST[@]}"; do
    if [ $i -eq 0 ]; then
        log_info "  ${SHORTID_LIST[$i]} (primary - used above)"
    else
        VLESS_ALT="vless://${UUID}@${SERVER_IP}:443?type=tcp&security=reality&pbk=${PUBLIC_KEY}&fp=chrome&sni=${DOMAIN}&sid=${SHORTID_LIST[$i]}&encryption=none#reality"
        log_info "  ${SHORTID_LIST[$i]} (alternative):"
        log_info "    $VLESS_ALT"
    fi
done
log_info ""
log_info "Service status:"
systemctl status xray --no-pager
