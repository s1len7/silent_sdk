#!/usr/bin/env bash
# Proxmox 저장소 설정 스크립트 (Proxmox 호스트에서 root로 실행)
# 기본으로 켜진 enterprise 저장소는 구독 키가 없으면 apt-get update가 실패(exit code 100)하므로 끄고,
# no-subscription 저장소를 추가한 뒤 최신 패치를 적용함
# 공식 문서: https://pve.proxmox.com/wiki/Package_Repositories
# 사용법: bash scripts/host/setup_pve_repo.sh
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

sources_dir=/etc/apt/sources.list.d
no_sub_file="$sources_dir/proxmox.sources"
codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"

# 켜져 있는 enterprise 저장소 파일 목록 (pve-enterprise.sources, ceph.sources 등)
enabled_enterprise_files() {
    local f
    for f in "$sources_dir"/*.sources; do
        [[ -f "$f" ]] || continue
        if grep -q 'enterprise\.proxmox\.com' "$f" && ! grep -qiE '^Enabled:[[:space:]]*no' "$f"; then
            echo "$f"
        fi
    done
}

no_subscription_added() {
    grep -rqs 'pve-no-subscription' /etc/apt/sources.list "$sources_dir"
}

# enterprise가 모두 꺼져 있고 no-subscription이 있으면 건너뜀 (웹 UI로 바꾼 경우도 포함)
if [[ -z "$(enabled_enterprise_files)" ]] && no_subscription_added; then
    skip_done "Proxmox repositories are already set up"
fi

# 1. enterprise 저장소 끄기 (각 항목의 Types 줄 다음에 Enabled: no 추가)
echo "[1/3] Disabling enterprise repositories"
while read -r f; do
    [[ -n "$f" ]] || continue
    sed -i '/^Types:/a Enabled: no' "$f"
    echo "Disabled: $f"
done <<< "$(enabled_enterprise_files)"

# 2. no-subscription 저장소 추가 (공식 문서의 내용과 같음)
echo "[2/3] Adding the no-subscription repository"
if ! no_subscription_added; then
    # 파일이 이미 있으면 빈 줄로 항목을 구분해 뒤에 추가
    [[ -s "$no_sub_file" ]] && echo >> "$no_sub_file"
    cat >> "$no_sub_file" <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: $codename
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
    echo "Added: $no_sub_file"
fi

# 3. 패키지 목록 갱신, 최신 패치 적용 (Proxmox는 upgrade가 아니라 full-upgrade를 사용)
echo "[3/3] Updating packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold full-upgrade

latest_kernel="$(find /boot -maxdepth 1 -name 'vmlinuz-*' -printf '%f\n' | sed 's/^vmlinuz-//' | sort -V | tail -1)"
if [[ -n "$latest_kernel" && "$latest_kernel" != "$(uname -r)" ]]; then
    echo "New kernel $latest_kernel installed (running $(uname -r)). Reboot to apply."
fi
echo "Proxmox repositories set up and packages updated."
