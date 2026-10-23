#!/usr/bin/env bash
# RTL-SDR 동글용 DVB-T 커널 드라이버 차단 스크립트
# 호스트 커널이 동글을 TV 수신기로 먼저 잡으면 ultrafeeder 컨테이너가 쓰지 못함 (usb_claim_interface error -6)
# 설정은 sdr-enthusiasts 가이드의 /etc/modprobe.d/exclusions-rtl2832.conf와 같음
# 사용법: sudo bash scripts/setup_dvb_blacklist.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

conf=/etc/modprobe.d/exclusions-rtl2832.conf
modules=(dvb_core dvb_usb_rtl2832u dvb_usb_rtl28xxu dvb_usb_v2 r820t rtl2830 rtl2832 rtl2832_sdr rtl2838)

# blacklist는 직접 로드만 막고, 다른 모듈의 의존성으로 로드되는 것은 install 줄로 막음
content="$(
    echo "# Keep the host from loading RTL-SDR DVB-T drivers so Docker containers can use the dongle"
    for m in "${modules[@]}"; do echo "blacklist $m"; done
    for m in "${modules[@]}"; do echo "install $m /bin/false"; done
)"

# 설정 파일 내용이 같으면 건너뜀
if [[ -f "$conf" && "$(cat "$conf")" == "$content" ]]; then
    skip_done "DVB drivers are already blacklisted"
fi

# 1. 차단 설정 파일 작성
echo "[1/3] Writing $conf"
echo "$content" > "$conf"

# 2. 이미 로드된 드라이버 내리기 (사용 중이면 실패하므로 재부팅 안내)
echo "[2/3] Unloading DVB drivers"
for m in "${modules[@]}"; do
    modprobe -r "$m" 2>/dev/null || true
done
loaded="$(lsmod | awk 'NR > 1 { print $1 }' | grep -xF -f <(printf '%s\n' "${modules[@]}") || true)"

# 3. 모듈 의존성 정보와 부팅 이미지(initramfs) 갱신, initramfs는 일부 시스템에만 필요하므로 실패해도 진행
echo "[3/3] Updating module dependencies and initramfs"
depmod -a
if ! update-initramfs -u; then
    echo "WARNING: update-initramfs failed, continuing (only needed on some systems)" >&2
fi

if [[ -n "$loaded" ]]; then
    echo "Some DVB drivers are still loaded ($(echo "$loaded" | paste -sd ' ')). Reboot to apply."
else
    echo "DVB drivers blacklisted."
fi
