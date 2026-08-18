#!/bin/bash
set -eo pipefail

echo "============================================"
echo " EasyTier + Landscape Edge"
echo "============================================"

# ---- Validate required env vars ----
if [ -z "${EASYTIER_USERNAME:-}" ]; then
    echo "ERROR: EASYTIER_USERNAME is required."
    echo "  Create an account at https://easytier.cn/web#/auth"
    echo "  Then set: -e EASYTIER_USERNAME=<your-username>"
    exit 1
fi

# ---- Build easytier-core args ----
ET_ARGS="-w ${EASYTIER_USERNAME}"
if [ -n "${EASYTIER_MACHINE_ID:-}" ]; then
    ET_ARGS="${ET_ARGS} --machine-id ${EASYTIER_MACHINE_ID}"
fi
if [ -n "${EASYTIER_HOSTNAME:-}" ]; then
    ET_ARGS="${ET_ARGS} --hostname ${EASYTIER_HOSTNAME}"
fi

# ---- Step 1: Start redirect_pkg_handler ----
echo "[1/3] Starting redirect_pkg_handler (route mode)..."
/usr/local/bin/redirect_pkg_handler -m route &
echo "   PID: $!"

# ---- Step 2: Start easytier-core ----
echo "[2/3] Starting easytier-core..."
echo "   Username: ${EASYTIER_USERNAME}"
echo "   Hostname: ${EASYTIER_HOSTNAME:-<auto>}"
echo "   Machine ID: ${EASYTIER_MACHINE_ID:-<auto>}"
/usr/local/bin/easytier-core ${ET_ARGS} &
ET_PID=$!
echo "   PID: ${ET_PID}"

# ---- Step 3: Wait for TUN device and configure NAT ----
echo "[3/3] Waiting for tun0 device..."
TUN_READY=false
for i in $(seq 1 10); do
    if ip link show tun0 >/dev/null 2>&1; then
        echo "   tun0 ready after ${i}s"
        TUN_READY=true
        break
    fi
    sleep 1
done

if [ "${TUN_READY}" = "false" ]; then
    echo "   WARNING: tun0 not ready after 10s, attempting NAT config anyway..."
fi

iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
echo "   NAT MASQUERADE on tun0 configured"

echo "============================================"
echo " All services started!"
echo ""
echo " EasyTier:    connecting to ${EASYTIER_USERNAME}'s network"
echo " NAT:         MASQUERADE on tun0"
echo ""
echo " Manage at:   https://easytier.cn/web#/auth"
echo "============================================"

# Wait for any child process to exit
wait -n
EXIT_CODE=$?
echo "Service exited with code ${EXIT_CODE}, shutting down..."
exit 1
