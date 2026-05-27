#!/usr/bin/env bash
# Run on the controller after fetching the WireGuard config:
#
#   make vpn-wireguard-config
#   bash scripts/test-wireguard.sh terraform/wg-<cloud>.conf
#
# Or use: make test-wireguard  (handles config download automatically)
#
# Requires wireproxy in PATH or WIREPROXY env var pointing to the binary.

set -euo pipefail

WG_CONF="${1:?usage: $0 <wg-config-file>}"
WIREPROXY="${WIREPROXY:-wireproxy}"

if ! command -v "${WIREPROXY}" >/dev/null 2>&1; then
    echo "ERROR: wireproxy not found (WIREPROXY=${WIREPROXY})"
    echo "  Install from https://github.com/pufferffish/wireproxy/releases"
    exit 1
fi

SOCKS_PORT=1080
SOCKS_ADDR="127.0.0.1:${SOCKS_PORT}"
tmpconf=$(mktemp)
wireproxy_pid=""

cleanup() {
    [[ -n "${wireproxy_pid}" ]] && kill "${wireproxy_pid}" 2>/dev/null || true
    rm -f "${tmpconf}"
}
trap cleanup EXIT

# Convert wg-quick config to wireproxy config:
# - strip MTU and DNS (wg-quick-specific, not supported by wireproxy)
# - ensure Address has a prefix length (wireproxy requires it)
# - append [Socks5] section
sed \
    -e '/^MTU\s*=/d' \
    -e '/^DNS\s*=/d' \
    -e 's/^\(Address\s*=\s*[0-9.]*\)$/\1\/32/' \
    "${WG_CONF}" > "${tmpconf}"
printf '\n[Socks5]\nBindAddress = %s\n' "${SOCKS_ADDR}" >> "${tmpconf}"

"${WIREPROXY}" -c "${tmpconf}" >/dev/null 2>&1 &
wireproxy_pid=$!

# Wait for the SOCKS5 listener to be ready (up to 10 s)
for _ in $(seq 1 20); do
    kill -0 "${wireproxy_pid}" 2>/dev/null || { echo "ERROR: wireproxy exited unexpectedly" >&2; exit 1; }
    { true < /dev/tcp/127.0.0.1/"${SOCKS_PORT}"; } 2>/dev/null && break
    sleep 0.5
done

failures=0

check() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        printf "PASS  %s\n" "${desc}"
    else
        printf "FAIL  %s\n" "${desc}"
        failures=$((failures + 1))
    fi
}

echo "WireGuard gateway connectivity"
echo

check "Keystone 192.168.16.254:5000" \
    curl -sk --socks5 "${SOCKS_ADDR}" --max-time 5 \
        https://192.168.16.254:5000/v3

echo
if [[ ${failures} -gt 0 ]]; then
    echo "FAILED (${failures})"
    exit 1
fi
echo "OK"
