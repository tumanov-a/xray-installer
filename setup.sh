#!/bin/bash

# Xray Reality VPN Setup Script
# Installs Xray, generates keys, and deploys server/client configs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="${1:-speed.cloudflare.com}"
NUM_SHORTIDS="${2:-2}"
CONFIG_DIR="/usr/local/etc/xray"
LOG_FILE="/tmp/xray_setup.log"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo -e "${RED}Run as root: sudo bash setup.sh [domain] [num_shortids]${NC}"
    exit 1
fi

if ! [[ "$NUM_SHORTIDS" =~ ^[0-9]+$ ]] || [[ "$NUM_SHORTIDS" -lt 1 ]]; then
    echo -e "${RED}num_shortids must be a positive integer${NC}"
    exit 1
fi

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Xray Reality VPN Setup${NC}"
echo -e "${GREEN}======================================${NC}"
echo "Domain: $DOMAIN"
echo "Number of ShortIds: $NUM_SHORTIDS"
echo "Config Directory: $CONFIG_DIR"
echo ""

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

parse_x25519_keys() {
    local output="$1"
    PRIVATE_KEY=$(echo "$output" | awk -F': ' '/PrivateKey:|Private key:/ {print $2; exit}')
    PUBLIC_KEY=$(echo "$output" | awk -F': ' '/Password \(PublicKey\):|Public key:/ {print $2; exit}')

    if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
        log_error "Failed to parse xray x25519 output:"
        echo "$output" >&2
        exit 1
    fi
}

apply_template() {
    local template="$1"
    local output="$2"
    local content

    if [[ ! -f "$template" ]]; then
        log_error "Template not found: $template"
        exit 1
    fi

    content=$(<"$template")
    content="${content//\{\{DOMAIN\}\}/$DOMAIN}"
    content="${content//\{\{PRIVATE_KEY\}\}/$PRIVATE_KEY}"
    content="${content//\{\{PUBLIC_KEY\}\}/$PUBLIC_KEY}"
    content="${content//\{\{UUID\}\}/$UUID}"
    content="${content//\{\{SHORTIDS_JSON\}\}/$SHORTIDS_JSON}"
    content="${content//\{\{SERVER_IP\}\}/$SERVER_IP}"
    content="${content//\{\{SHORTID_1\}\}/$SHORTID1}"

    printf '%s\n' "$content" > "$output"
}

log_info "Step 1: Installing Xray..."
bash <(curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
log_info "Xray installed successfully"

log_info "Step 2: Generating cryptographic keys..."
KEY_OUTPUT=$(xray x25519)
parse_x25519_keys "$KEY_OUTPUT"
log_info "Private Key: $PRIVATE_KEY"
log_info "Public Key: $PUBLIC_KEY"

log_info "Step 3: Generating UUID..."
UUID=$(xray uuid)
log_info "UUID: $UUID"

log_info "Step 4: Generating $NUM_SHORTIDS shortIds..."
SHORTID_LIST=()
for _ in $(seq 1 "$NUM_SHORTIDS"); do
    SHORTID_LIST+=("$(openssl rand -hex 8)")
done

SHORTIDS_JSON="["
for i in "${!SHORTID_LIST[@]}"; do
    if [[ $i -gt 0 ]]; then
        SHORTIDS_JSON+=","
    fi
    SHORTIDS_JSON+="\"${SHORTID_LIST[$i]}\""
done
SHORTIDS_JSON+="]"

SHORTID1="${SHORTID_LIST[0]}"
for i in "${!SHORTID_LIST[@]}"; do
    log_info "ShortId $((i + 1)): ${SHORTID_LIST[$i]}"
done
log_info "Primary ShortId for client: $SHORTID1"

SERVER_IP=$(hostname -I | awk '{print $1}')

log_info "Step 5: Creating server configuration..."
mkdir -p "$CONFIG_DIR"
apply_template "$SCRIPT_DIR/config.json.template" "$CONFIG_DIR/config.json"
log_info "Server configuration created at $CONFIG_DIR/config.json"

log_info "Validating server configuration..."
xray run -test -config "$CONFIG_DIR/config.json"

log_info "Step 6: Configuring firewall..."
if command -v ufw >/dev/null 2>&1; then
    ufw allow 443/tcp || log_warn "UFW rule for 443/tcp may already exist"
else
    log_warn "UFW not installed; ensure port 443/tcp is open"
fi

log_info "Step 7: Starting Xray service..."
systemctl enable xray
systemctl restart xray
log_info "Xray service started and enabled"

log_info "Step 8: Generating client configuration..."
apply_template "$SCRIPT_DIR/client_config.json.template" /tmp/client_config.json
log_info "Client configuration created at /tmp/client_config.json"

build_vless_uri() {
    local sid="$1"
    echo "vless://${UUID}@${SERVER_IP}:443?type=tcp&security=reality&pbk=${PUBLIC_KEY}&fp=chrome&sni=${DOMAIN}&sid=${sid}&encryption=none#reality"
}

KEYS_FILE="$SCRIPT_DIR/keys.txt"
{
    echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "Domain: $DOMAIN"
    echo "Server IP: $SERVER_IP"
    echo "PrivateKey: $PRIVATE_KEY"
    echo "PublicKey: $PUBLIC_KEY"
    echo "UUID: $UUID"
    echo "ShortIds: $SHORTIDS_JSON"
    echo ""
    echo "VLESS URIs:"
    for sid in "${SHORTID_LIST[@]}"; do
        echo "- $(build_vless_uri "$sid")"
    done
} > "$KEYS_FILE"

log_info ""
log_info "=========================================="
log_info "Installation completed successfully!"
log_info "=========================================="
log_info "Domain: $DOMAIN"
log_info "Server IP: $SERVER_IP"
log_info "UUID: $UUID"
log_info "Client config: /tmp/client_config.json"
log_info "Server config: $CONFIG_DIR/config.json"
log_info ""
log_info "VLESS URIs for Client Applications:"
log_info "=========================================="

for i in "${!SHORTID_LIST[@]}"; do
    uri=$(build_vless_uri "${SHORTID_LIST[$i]}")
    echo -e "${BLUE}[$((i + 1))] ${uri}${NC}"
    log_info "ShortId $((i + 1)): ${SHORTID_LIST[$i]}"
done
echo ""

log_info ""
log_info "Service status:"
systemctl status xray --no-pager
