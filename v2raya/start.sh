#!/bin/bash
set -e

echo "============================================"
echo " v2rayA + Landscape Edge"
echo "============================================"

# ---- Step 1: TProxy 路由规则 ----
# redirect_pkg_handler 会给包标记 fwmark 0x1
# 这些规则让被标记的包走本地投递，v2rayA 的 TProxy socket 才能接住
echo "[1/3] Setting up TProxy routing rules..."

ip rule add fwmark 0x1/0x1 lookup 100
ip route add local default dev lo table 100

ip -6 rule add fwmark 0x1 lookup 106
ip -6 route add local ::/0 dev lo table 106

echo "   IPv4: fwmark 0x1 -> table 100 -> local lo"
echo "   IPv6: fwmark 0x1 -> table 106 -> local lo"

# ---- Step 2: 启动 v2rayA ----
echo "[2/3] Starting v2rayA..."
/usr/bin/v2raya &

# 等待 Web UI 就绪 (最多 30 秒)
echo "   Waiting for v2rayA web UI (port 2017)..."
for i in $(seq 1 30); do
    if ss -tlnp 2>/dev/null | grep -q ":2017 "; then
        echo "   v2rayA web UI ready"
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "   WARNING: v2rayA web UI not ready after 30s, continuing anyway..."
    fi
    sleep 1
done

# ---- Step 3: 启动 redirect_pkg_handler ----
echo "[3/3] Starting redirect_pkg_handler..."
echo "   TProxy target: 0.0.0.0:12345 (default)"
echo "   Override with: LAND_PROXY_SERVER_PORT env var"
/usr/local/bin/redirect_pkg_handler &

echo "============================================"
echo " All services started!"
echo ""
echo " Web UI:   http://<host-ip>:2017"
echo " TProxy:   12345 (configure in Web UI)"
echo "============================================"

# 等待任意子进程退出
wait -n
EXIT_CODE=$?
echo "Service exited with code $EXIT_CODE, shutting down..."
exit 1
