#!/usr/bin/env bash
# 부팅 완료 비프음 활성화 스크립트 (라즈베리파이 공통 모듈, pi5도 사용)
# 소리를 낼 수 있는 출력이 확인되면 사운드로, 아니면 부저로 울림 (판단은 /usr/local/bin/boot-beep이 부팅 때마다 함)
#   1. USB 사운드카드·스피커 (카드가 있으면 연결된 것)
#   2. 오디오를 받는 HDMI 모니터 (모니터가 보내는 ELD 정보로 확인)
#   3. 3.5mm 단자 (꽂혔는지 알 수 없어 /etc/default/boot-beep의 BOOT_BEEP_ANALOG=yes일 때만, Pi 5에는 단자 없음)
#   4. 위가 없거나 재생에 실패하면 능동 부저
# 배선: 능동 부저(High level trigger) I/O - 18번 핀(GPIO24), GND - 20번 핀
# 사용법: sudo bash scripts/setup_boot_beep.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

unit_file=/etc/systemd/system/boot-beep.service
runner_file=/usr/local/bin/boot-beep
sound_dir=/usr/local/share/boot-beep
sound_file="$sound_dir/beep.wav"
default_file=/etc/default/boot-beep

# Type=idle: 부팅 작업이 모두 끝난 뒤 실행되도록 함
unit="$(cat <<EOF
[Unit]
Description=Beep when boot is complete

[Service]
Type=idle
ExecStart=$runner_file

[Install]
WantedBy=multi-user.target
EOF
)"

runner="$(cat <<'EOF'
#!/bin/sh
# 부팅 완료 비프음: 사운드 출력이 확인되면 소리로, 아니면 GPIO24의 부저로 울림 (setup_boot_beep.sh가 설치)
# 순서: USB 사운드 → 오디오를 받는 HDMI 모니터 → 3.5mm 단자(BOOT_BEEP_ANALOG=yes일 때만) → 부저
BOOT_BEEP_ANALOG=no
[ -r /etc/default/boot-beep ] && . /etc/default/boot-beep
wav=/usr/local/share/boot-beep/beep.wav

# 카드 번호($1)에 오디오를 받는 HDMI 모니터가 연결돼 있으면 0 (ELD가 유효하거나 비어 있지 않음)
hdmi_ready() {
    for f in /proc/asound/card"$1"/eld*; do
        [ -f "$f" ] && grep -q 'eld_valid[[:space:]]*1' "$f" && return 0
    done
    amixer -c "$1" cget iface=PCM,name=ELD 2>/dev/null | grep ': values=' | grep -Eq '0x0*[1-9a-f]'
}

# 카드 번호($1)로 비프음을 재생, 성공하면 0
play() {
    aplay -q -D "plughw:$1,0" "$wav" 2>/dev/null || return 1
    echo "Boot beep played on sound card $1 ($(cat /proc/asound/card"$1"/id))"
}

usb='' hdmi='' analog=''
for card in /proc/asound/card[0-9]*; do
    [ -d "$card" ] || continue
    n="${card##*card}"
    id="$(cat "$card/id" 2>/dev/null)"
    if [ -e "$card/usbid" ]; then
        usb="$usb $n"
    else
        case "$id" in
            *[Hh][Dd][Mm][Ii]*) hdmi="$hdmi $n" ;;
            Headphones) analog="$n" ;;
        esac
    fi
done

for n in $usb; do play "$n" && exit 0; done
for n in $hdmi; do hdmi_ready "$n" && play "$n" && exit 0; done
if [ "$BOOT_BEEP_ANALOG" = yes ] && [ -n "$analog" ]; then
    play "$analog" && exit 0
fi

pinctrl set 24 op dh
sleep 0.2
pinctrl set 24 op dl
echo "Boot beep played on the buzzer (GPIO24), no sound output found"
EOF
)"

# 서비스 파일·실행 파일이 같고, 소리 파일과 설정 파일이 있고, 등록돼 있으면 건너뜀 (테스트 비프음도 울리지 않음)
if [[ -f "$unit_file" && "$(cat "$unit_file")" == "$unit" ]] \
    && [[ -f "$runner_file" && "$(cat "$runner_file")" == "$runner" ]] \
    && [[ -s "$sound_file" && -f "$default_file" ]] \
    && systemctl is-enabled --quiet boot-beep.service; then
    skip_done "boot-beep.service is already enabled"
fi

# 부저용 pinctrl은 필수, 사운드용 aplay는 없으면 부저로만 울림
if ! command -v pinctrl >/dev/null 2>&1; then
    echo "pinctrl not found. Install with: sudo apt install raspi-utils" >&2
    exit 1
fi
if ! command -v aplay >/dev/null 2>&1; then
    echo "aplay not found, the beep will use the buzzer only (install alsa-utils for sound)" >&2
fi

# 0.25초 880Hz 비프음 (앞뒤를 짧게 줄여 딸깍 소리를 막음)
if [[ ! -s "$sound_file" ]]; then
    mkdir -p "$sound_dir"
    python3 - "$sound_file" <<'EOF'
import math
import struct
import sys
import wave

rate = 44100
length = int(rate * 0.25)
fade = int(rate * 0.01)
frames = bytearray()
for i in range(length):
    gain = min(1.0, i / fade, (length - i) / fade)
    sample = 0.5 * gain * math.sin(2 * math.pi * 880 * i / rate)
    frames += struct.pack("<h", int(sample * 32767))
with wave.open(sys.argv[1], "wb") as out:
    out.setnchannels(1)
    out.setsampwidth(2)
    out.setframerate(rate)
    out.writeframes(bytes(frames))
EOF
    echo "Beep sound created: $sound_file"
fi

# 사용자가 바꾼 설정은 덮어쓰지 않음
if [[ ! -f "$default_file" ]]; then
    cat > "$default_file" <<'EOF'
# 부팅 완료 비프음 설정 (/usr/local/bin/boot-beep이 읽음)
# 3.5mm 단자에 스피커를 연결했으면 yes (꽂혔는지 알 수 없어 기본은 no, Pi 5에는 단자 없음)
BOOT_BEEP_ANALOG=no
EOF
    echo "Settings created: $default_file"
fi

printf '%s\n' "$runner" > "$runner_file"
chmod 755 "$runner_file"
printf '%s\n' "$unit" > "$unit_file"
systemctl daemon-reload
systemctl enable boot-beep.service
echo "boot-beep.service enabled"

# 설치 확인용으로 한 번 울림 (부팅 때 어느 쪽으로 울렸는지는 journalctl -u boot-beep에 남음)
"$runner_file"
