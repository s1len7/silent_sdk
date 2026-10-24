#!/usr/bin/env bash
# Wi-Fi 연결 스크립트 (Proxmox 호스트에서 root로 실행)
# 유선(vmbr0)은 그대로 두고 호스트의 Wi-Fi도 공유기에 연결함 (Wi-Fi는 브리지에 넣을 수 없으므로 VM은 계속 vmbr0 사용)
# ifupdown2에는 Wi-Fi 인증 기능이 없고 dhcp에 경로 테이블 지정도 없으므로,
# 인증은 wpa_supplicant@<인터페이스>, DHCP는 Wi-Fi 인터페이스만 맡긴 systemd-networkd로 함
# 케이블이 빠져도 VM 포트(tap) 때문에 vmbr0이 살아 있는 것으로 보여 Wi-Fi로 들어온 접속의 응답이 vmbr0으로 나가므로,
# Wi-Fi로 들어온 연결에 nftables 표시(connmark)를 붙이고 그 응답은 Wi-Fi 경로 테이블로 보냄 (DHCP 주소가 바뀌어도 동작)
# 값은 devices/b150m-am2/.env의 WIFI_SSID, WIFI_PASSWORD에서 읽고, WIFI_SSID가 비어 있으면 건너뜀
# 사용법: bash scripts/host/setup_wifi.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run as root: bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/../lib.sh"

if ! command -v pveversion >/dev/null; then
    echo "Not a Proxmox host. Run this script on the Proxmox host." >&2
    exit 1
fi

device_dir="$(cd "$(dirname "$0")/../.." && pwd)"
env_file="$device_dir/.env"
if [[ -f "$env_file" ]]; then
    # Windows에서 편집해 CR이 들어갔으면 제거
    sed -i 's/\r$//' "$env_file"
    # shellcheck source=/dev/null
    source "$env_file"
fi

ssid="${WIFI_SSID:-}"
password="${WIFI_PASSWORD:-}"
country="${WIFI_COUNTRY:-}"
# Wi-Fi DHCP 경로를 넣는 테이블 번호와, Wi-Fi로 들어온 연결에 붙이는 표시 값
route_table=100
fw_mark=100

if [[ -z "$ssid" ]]; then
    skip_done "WIFI_SSID is empty in $env_file (set it to connect Wi-Fi)"
fi

# Wi-Fi 인터페이스: .env의 WIFI_INTERFACE, 없으면 첫 번째 무선 인터페이스
iface="${WIFI_INTERFACE:-}"
if [[ -z "$iface" ]]; then
    for d in /sys/class/net/*/wireless; do
        [[ -d "$d" ]] && { iface="$(basename "$(dirname "$d")")"; break; }
    done
fi
if [[ -z "$iface" || ! -d "/sys/class/net/$iface/wireless" ]]; then
    echo "No Wi-Fi interface found${iface:+ ($iface)}. Check the adapter and driver (ip link)." >&2
    exit 1
fi
# /etc/network/interfaces에도 있으면 ifupdown2와 충돌하므로 중단
if grep -qsE "^[[:space:]]*(auto|allow-hotplug|iface)[[:space:]]+$iface([[:space:]]|$)" \
    /etc/network/interfaces /etc/network/interfaces.d/*; then
    echo "$iface is configured in /etc/network/interfaces. Remove it there first." >&2
    exit 1
fi

pkgs=(wpasupplicant iw wireless-regdb nftables)
wpa_conf="/etc/wpa_supplicant/wpa_supplicant-$iface.conf"
network_file="/etc/systemd/network/50-wifi-$iface.network"
networkd_conf=/etc/systemd/networkd.conf.d/50-wifi-only.conf
nft_file=/etc/nftables.d/50-wifi-failover.nft
nft_unit=wifi-failover-nft.service
nft_unit_file="/etc/systemd/system/$nft_unit"
sysctl_file=/etc/sysctl.d/50-wifi-arp.conf
power_save_file="/etc/systemd/system/wpa_supplicant@$iface.service.d/50-power-save-off.conf"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# 원하는 설정 파일 내용을 만들어 두고 기존 파일과 비교 (SSID·비밀번호가 바뀌면 다시 적용)
# wpa_supplicant 설정: 비밀번호는 wpa_passphrase로 해시한 psk만 남김
build_wpa_conf() {
    [[ -n "$country" ]] && echo "country=$country"
    if [[ -n "$password" ]]; then
        if ! wpa_passphrase "$ssid" "$password" | grep -v '^[[:space:]]*#psk='; then
            echo "Invalid Wi-Fi password (WPA needs 8-63 characters)." >&2
            return 1
        fi
    else
        printf 'network={\n\tssid="%s"\n\tkey_mgmt=NONE\n}\n' "$ssid"
    fi
}

# DHCP 경로는 main이 아닌 별도 테이블에 넣어 유선 경로와 겹치지 않게 하고, 표시가 붙은 패킷만 그 테이블을 씀
cat > "$work/network" <<EOF
[Match]
Name=$iface

[Network]
DHCP=ipv4

[DHCPv4]
RouteTable=$route_table

[RoutingPolicyRule]
FirewallMark=$fw_mark
Table=$route_table
EOF

# Wi-Fi로 들어온 연결에 표시를 붙이고, 그 연결의 응답 패킷에도 같은 표시를 붙여 경로를 다시 고르게 함
# 자기 테이블만 지우고 다시 만듦 (다른 nftables 규칙은 건드리지 않음)
cat > "$work/nft" <<EOF
table inet wifi_failover
delete table inet wifi_failover
table inet wifi_failover {
    chain prerouting {
        type filter hook prerouting priority mangle; policy accept;
        iifname "$iface" ct mark set $fw_mark
    }
    chain output {
        type route hook output priority mangle; policy accept;
        ct mark $fw_mark meta mark set $fw_mark
    }
}
EOF

# 유선·Wi-Fi가 같은 대역이면 각 인터페이스가 상대 IP의 ARP에도 답해서(ARP flux), 케이블이 빠진 직후
# 공유기·PC가 Wi-Fi IP를 유선 MAC으로 기억해 30초쯤 접속이 안 되므로, IP가 붙은 인터페이스에서만 답하게 함
cat > "$work/sysctl.conf" <<'EOF'
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2
EOF

# Wi-Fi 절전 모드가 켜져 있으면 들어오는 패킷이 빠져(실측 ping 손실 50%) Wi-Fi IP로 접속이 끊기므로,
# Wi-Fi 서비스가 시작될 때마다 절전을 끔 (iw가 실패해도 Wi-Fi 연결은 계속되게 '-'를 붙임)
cat > "$work/power-save.conf" <<'EOF'
[Service]
ExecStartPost=-/usr/sbin/iw dev %i set power_save off
EOF

cat > "$work/nft.service" <<EOF
[Unit]
Description=Mark connections arriving on Wi-Fi $iface (silent_sdk setup_wifi.sh)
Before=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/nft -f $nft_file
ExecStop=/usr/sbin/nft delete table inet wifi_failover

[Install]
WantedBy=multi-user.target
EOF

# networkd가 ifupdown2가 만든 경로·규칙(vmbr0 등)을 지우지 않게 함
cat > "$work/networkd.conf" <<'EOF'
[Network]
ManageForeignRoutingPolicyRules=no
ManageForeignRoutes=no
ManageForeignNextHops=no
EOF

wifi_ready() {
    pkgs_installed "${pkgs[@]}" \
        && cmp -s "$work/wpa.conf" "$wpa_conf" \
        && cmp -s "$work/network" "$network_file" \
        && cmp -s "$work/networkd.conf" "$networkd_conf" \
        && cmp -s "$work/nft" "$nft_file" \
        && cmp -s "$work/nft.service" "$nft_unit_file" \
        && cmp -s "$work/sysctl.conf" "$sysctl_file" \
        && cmp -s "$work/power-save.conf" "$power_save_file" \
        && systemctl is-active --quiet systemd-networkd "wpa_supplicant@$iface" "$nft_unit"
}

# 1. 패키지 설치 (wpa_passphrase가 필요하므로 설정 비교보다 먼저)
if ! pkgs_installed "${pkgs[@]}"; then
    echo "[1/4] Installing ${pkgs[*]}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y "${pkgs[@]}"
fi

build_wpa_conf > "$work/wpa.conf"

if wifi_ready; then
    skip_done "Wi-Fi ($iface) is already configured for $ssid"
fi

# 2. 설정 파일 설치 (wpa 설정은 비밀번호 해시가 있으므로 root만 읽게 함)
echo "[2/4] Writing Wi-Fi config for $iface ($ssid)"
install -m 600 "$work/wpa.conf" "$wpa_conf"
install -D -m 644 "$work/network" "$network_file"
install -D -m 644 "$work/networkd.conf" "$networkd_conf"
install -D -m 644 "$work/nft" "$nft_file"
install -m 644 "$work/nft.service" "$nft_unit_file"
install -m 644 "$work/sysctl.conf" "$sysctl_file"
install -D -m 644 "$work/power-save.conf" "$power_save_file"
sysctl -q -p "$sysctl_file"

# 3. 서비스 시작 (networkd는 .network 파일이 있는 Wi-Fi만 관리하고 vmbr0 등은 건드리지 않음)
#    wait-online은 Wi-Fi가 안 잡히면 부팅을 지연시키므로 끔
echo "[3/4] Starting $nft_unit, wpa_supplicant@$iface and systemd-networkd"
systemctl daemon-reload
systemctl enable "$nft_unit"
systemctl restart "$nft_unit"
systemctl enable systemd-networkd
systemctl disable systemd-networkd-wait-online.service 2>/dev/null || true
# 이전 설정의 정책 규칙·경로는 networkd가 재시작 후 남의 것으로 보고 지우지 않으므로 먼저 지움
while ip rule del table "$route_table" 2>/dev/null; do :; done
ip route flush table "$route_table" 2>/dev/null || true
systemctl restart systemd-networkd
systemctl enable "wpa_supplicant@$iface"
systemctl restart "wpa_supplicant@$iface"

# 4. IP를 받을 때까지 최대 30초 대기
echo "[4/4] Waiting for an IPv4 address on $iface"
for _ in {1..30}; do
    addr="$(ip -4 -o addr show dev "$iface" | awk '{ print $4 }' | head -n 1)"
    [[ -n "$addr" ]] && break
    sleep 1
done
if [[ -z "$addr" ]]; then
    echo "No IPv4 address on $iface. Check WIFI_SSID / WIFI_PASSWORD, then: journalctl -u wpa_supplicant@$iface" >&2
    exit 1
fi

echo "Wi-Fi connected: $iface $addr"
ip route show default
