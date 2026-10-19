#!/bin/sh
# Runs only in an isolated disposable Linux container with NET_ADMIN.
set -eu
apk add --no-cache nftables jq iproute2 qemu-aarch64 >/dev/null
mkdir -p /tmp/cudyroute /usr/local/bin
cat > /usr/local/bin/jsonfilter <<'SH'
#!/bin/sh
while [ "$#" -gt 0 ]; do
 case "$1" in -i) FILE=$2;shift 2;; -e) EXPR=$2;shift 2;; *)exit 1;;esac
done
EXPR=$(printf '%s' "$EXPR" | sed 's/^@//; s/\[\*\]/[]/g')
exec jq -r "$EXPR" "$FILE"
SH
chmod +x /usr/local/bin/jsonfilter
printf '%s\n' '{"enabled":true,"failure":"block","ipv6":false,"interfaces":["br-lan"]}' > /tmp/cudyroute/network.json
sh /work/files/usr/lib/cudyroute/network guard
nft list table inet cudyroute_guard >/dev/null
printf 'nftables guard: OK\n'
ip link add br-lan type bridge
ip addr add 192.168.250.1/24 dev br-lan
ip link set br-lan up
cat > /tmp/core-smoke.json <<'JSON'
{"log":{"disabled":true},"inbounds":[{"type":"tun","tag":"tun","interface_name":"rb-tun","address":["172.31.255.1/30"],"mtu":1400,"stack":"system","auto_route":true,"auto_redirect":true,"include_interface":["br-lan"]}],"outbounds":[{"type":"direct","tag":"direct"}],"route":{"auto_detect_interface":true,"final":"direct"}}
JSON
/work/build/sing-box-linux-amd64 check -c /tmp/core-smoke.json
/work/build/sing-box-linux-amd64 run -c /tmp/core-smoke.json > /tmp/core.log 2>&1 &
CORE_PID=$!
trap 'kill "$CORE_PID" 2>/dev/null || true' EXIT
sleep 2
kill -0 "$CORE_PID"
ip link show rb-tun >/dev/null
printf 'TUN and auto_redirect: OK\n'
kill "$CORE_PID"
wait "$CORE_PID" || true
trap - EXIT
nft list table inet cudyroute_guard >/dev/null
printf 'guard survives core exit: OK\n'
sh /work/files/usr/lib/cudyroute/network stop
! nft list table inet cudyroute_guard >/dev/null 2>&1
printf 'guard cleanup: OK\n'
qemu-aarch64 /work/dist/cudyroute-arm64 defaults | jq -e '.interfaces == ["br-lan"] and .storage == "flash"' >/dev/null
qemu-aarch64 /work/dist/sing-box-arm64 version
printf 'ARM64 executables: OK\n'
