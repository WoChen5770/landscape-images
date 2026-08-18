#!/bin/sh
# ip6tables wrapper - supports IPTABLES_MODE env var
# Source: v2rayA/v2rayA (install/docker/ip6tables.sh)

if [ "$IPTABLES_MODE" = "nftables" ]; then
    /usr/sbin/ip6tables-nft "$@"
elif [ "$IPTABLES_MODE" = "legacy" ]; then
    /usr/sbin/ip6tables-legacy "$@"
else
    /usr/sbin/ip6tables "$@"
fi
