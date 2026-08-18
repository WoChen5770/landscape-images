#!/bin/sh
# iptables wrapper - supports IPTABLES_MODE env var
# Source: v2rayA/v2rayA (install/docker/iptables.sh)

if [ "$IPTABLES_MODE" = "nftables" ]; then
    /usr/sbin/iptables-nft "$@"
elif [ "$IPTABLES_MODE" = "legacy" ]; then
    /usr/sbin/iptables-legacy "$@"
else
    /usr/sbin/iptables "$@"
fi
