#!/usr/bin/env bash
# Wi-Fi 연결 스크립트 (Proxmox 호스트에서 root로 실행)
# 유선(vmbr0)은 그대로 두고 호스트의 Wi-Fi도 공유기에 연결함 (Wi-Fi는 브리지에 넣을 수 없으므로 VM은 계속 vmbr0 사용)
# ifupdown2에는 Wi-Fi 인증 기능이 없고 dhcp에 route metric도 없어 Wi-Fi 기본 경로가 유선과 겹치므로,
# 인증은 wpa_supplicant@<인터페이스>, DHCP는 Wi-Fi 인터페이스만 맡긴 systemd-networkd(metric 600, 유선이 우선)로 함
# 값은 devices/b150m-am2/.env의 WIFI_SSID, WIFI_PASSWORD에서 읽고, WIFI_SSID가 비어 있으면 건너뜀
# WIFI_IP(고정 IP)를 넣으면 유선이 끊겨도 Wi-Fi 주소로 호스트에 접속되도록 정책 라우팅을 추가함
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
wifi_ip="${WIFI_IP:-}"
wifi_gateway="${WIFI_GATEWAY:-}"
# Wi-Fi 주소에서 나가는 패킷용 경로 테이블 번호 (고정 IP일 때만 사용)
route_table=100

if [[ -z "$ssid" ]]; then
    skip_done "WIFI_SSID is empty in $env_file (set it to connect Wi-Fi)"
fi
if [[ -n "$wifi_ip" ]]; then
    [[ "$wifi_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ && ${wifi_ip#*/} -le 32 ]] \
        || { echo "WIFI_IP must be CIDR (e.g. 192.168.0.25/24): $wifi_ip" >&2; exit 1; }
    [[ -n "$wifi_gateway" ]] || { echo "WIFI_GATEWAY is required with WIFI_IP" >&2; exit 1; }
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

pkgs=(wpasupplicant iw wireless-regdb)
wpa_conf="/etc/wpa_supplicant/wpa_supplicant-$iface.conf"
network_file="/etc/systemd/network/50-wifi-$iface.network"
networkd_conf=/etc/systemd/networkd.conf.d/50-wifi-only.conf

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

# CIDR(예: 192.168.0.25/24)의 네트워크 주소 (예: 192.168.0.0/24)
network_of() {
    local a b c d len="${1#*/}" n
    IFS=. read -r a b c d <<< "${1%/*}"
    n=$(( ((a << 24) | (b << 16) | (c << 8) | d) & ((0xFFFFFFFF << (32 - len)) & 0xFFFFFFFF) ))
    echo "$(( n >> 24 & 255 )).$(( n >> 16 & 255 )).$(( n >> 8 & 255 )).$(( n & 255 ))/$len"
}

if [[ -z "$wifi_ip" ]]; then
    cat > "$work/network" <<EOF
[Match]
Name=$iface

[Network]
DHCP=ipv4

[DHCPv4]
RouteMetric=600
EOF
else
    # 고정 IP: 케이블이 빠져도 VM 포트(tap) 때문에 vmbr0이 살아 있는 것으로 보여
    # Wi-Fi 주소로 들어온 접속의 응답이 vmbr0으로 나가므로, Wi-Fi 주소에서 나가는 패킷은 별도 경로 테이블로 보냄
    cat > "$work/network" <<EOF
[Match]
Name=$iface

[Address]
Address=$wifi_ip
RouteMetric=600

[Route]
Gateway=$wifi_gateway
Metric=600

[Route]
Destination=$(network_of "$wifi_ip")
Table=$route_table

[Route]
Gateway=$wifi_gateway
Table=$route_table

[RoutingPolicyRule]
From=${wifi_ip%/*}
Table=$route_table
EOF
fi

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
        && systemctl is-active --quiet systemd-networkd "wpa_supplicant@$iface"
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

# 3. 서비스 시작 (networkd는 .network 파일이 있는 Wi-Fi만 관리하고 vmbr0 등은 건드리지 않음)
#    wait-online은 Wi-Fi가 안 잡히면 부팅을 지연시키므로 끔
echo "[3/4] Starting wpa_supplicant@$iface and systemd-networkd"
systemctl enable systemd-networkd
systemctl disable systemd-networkd-wait-online.service 2>/dev/null || true
# 예전 고정 IP의 정책 규칙·경로는 networkd가 재시작 후 남의 것으로 보고 지우지 않으므로 먼저 지움
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
