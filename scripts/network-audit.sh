#!/usr/bin/env bash
# Network Audit Script — Ember Browser
# Verifies that a built Chromium binary makes no outbound connections
# to Google services, telemetry endpoints, or tracking domains.
#
# Usage:
#   ./network-audit.sh /path/to/chrome
#
# Requires: tcpdump, Wireshark (tshark optional), Chromium binary

set -euo pipefail

CHROME_BIN="${1:?Usage: $0 /path/to/chrome}"
AUDIT_DIR="$(dirname "$0")/../audit"
LOG_FILE="${AUDIT_DIR}/network-audit-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "${AUDIT_DIR}"

# Known Google/telemetry domains to check for
BLOCKED_DOMAINS=(
    "google.com"
    "googleapis.com"
    "gstatic.com"
    "google.co.uk"
    "google-analytics.com"
    "googletagmanager.com"
    "doubleclick.net"
    "googlesyndication.com"
    "googleadservices.com"
    "crashpad.google.com"
    "clients2.google.com"
    "safebrowsing.googleapis.com"
    "update.googleapis.com"
    "play.googleapis.com"
    "accounts.google.com"
    "chrome.google.com"
    "chromium.appspot.com"
    "maas.appspot.com"
)

log() { echo -e "\033[1;32m[audit]\033[0m $*"; }
warn() { echo -e "\033[1;33m[audit]\033[0m $*"; }
fail() { echo -e "\033[1;31m[audit]\033[0m $*"; }

log "=== Ember Network Audit ==="
log "Binary: ${CHROME_BIN}"
log "Log: ${LOG_FILE}"

# Step 1: Verify binary exists
if [[ ! -f "${CHROME_BIN}" ]]; then
    fail "Binary not found: ${CHROME_BIN}"
    exit 1
fi

# Step 2: Check for Google API keys compiled in
log "Checking for embedded Google API keys..."
if strings "${CHROME_BIN}" | grep -qi "AIza[0-9A-Za-z_-]\{35\}"; then
    fail "Google API key found in binary!"
    echo "GOOGLE_API_KEY_FOUND" >> "${LOG_FILE}"
else
    log "No Google API keys found in binary."
fi

# Step 3: Check for telemetry symbols
log "Checking for telemetry/crash reporting symbols..."
TELEMETRY_SYMBOLS=(
    "uma"
    "metrics"
    "crashpad"
    "breakpad"
    "safebrowsing"
    "google_update"
    "omaha"
    "feedback.google"
)

found_telemetry=0
for sym in "${TELEMETRY_SYMBOLS[@]}"; do
    if strings "${CHROME_BIN}" | grep -qi "${sym}"; then
        warn "Telemetry symbol found: ${sym}"
        echo "TELEMETRY_SYMBOL: ${sym}" >> "${LOG_FILE}"
        found_telemetry=1
    fi
done

if [[ $found_telemetry -eq 0 ]]; then
    log "No telemetry symbols found."
fi

# Step 4: Network capture (requires root for tcpdump)
log ""
log "To complete the audit, run a network capture:"
log "  1. Start capture: sudo tcpdump -i any -w ${AUDIT_DIR}/capture.pcap"
log "  2. Launch browser: ${CHROME_BIN} --no-first-run --user-data-dir=/tmp/ember-audit"
log "  3. Browse for 60 seconds (visit a few sites)"
log "  4. Stop capture: sudo killall tcpdump"
log "  5. Analyze: tshark -r ${AUDIT_DIR}/capture.pcap -T fields -e dns.qry.name | sort -u"
log ""
log "Check for connections to any of these blocked domains:"
for domain in "${BLOCKED_DOMAINS[@]}"; do
    log "  - ${domain}"
done

log ""
log "Audit script complete. Manual network capture required for full verification."
