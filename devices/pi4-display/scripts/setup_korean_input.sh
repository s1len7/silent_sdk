#!/usr/bin/env bash
# 한글 입력기(fcitx5-hangul) 설치: 화면에서 한글을 입력할 수 있게 함
# 1) 패키지 설치 2) im-config로 로그인 시 fcitx5 실행 3) 입력기 목록에 한글 추가 4) 한/영 전환 키 설정
# 전환 키: fcitx5 기본값(Ctrl+Space, Zenkaku_Hankaku, 한/영 키)에 한/영 키가 없는 키보드를 위해 Shift+Space를 더함
# 사용법: sudo bash scripts/setup_korean_input.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

# sudo로 실행해도 sudo한 사용자에게 설정함 (root로 직접 로그인했으면 root)
user="${SUDO_USER:-root}"
user_home="$(getent passwd "$user" | cut -d: -f6)"
if [[ -z "$user_home" || ! -d "$user_home" ]]; then
    echo "Home directory not found for user $user" >&2
    exit 1
fi
conf_dir="$user_home/.config/fcitx5"
profile="$conf_dir/profile"
config="$conf_dir/config"
xinputrc="$user_home/.xinputrc"

# Debian 공식 저장소 패키지 (fcitx5·fcitx5-hangul: LGPL-2.1+, im-config: GPL-2+)
# frontend-all: GTK·Qt 앱 입력 모듈, config-qt: 설정 도구(fcitx5-configtool)
pkgs=(fcitx5 fcitx5-hangul fcitx5-frontend-all fcitx5-config-qt im-config)
trigger_keys=(Control+space Zenkaku_Hankaku Hangul Shift+space)

as_user() {
    sudo -u "$user" -H "$@"
}

im_selected() {
    grep -qs '^run_im fcitx5$' "$xinputrc"
}

profile_has_hangul() {
    grep -qs '^Name=hangul$' "$profile"
}

# config의 [Hotkey/TriggerKeys] 절에 전환 키가 모두 있으면 0
trigger_keys_set() {
    local section key
    section="$(awk '/^\[/ { s = ($0 == "[Hotkey/TriggerKeys]"); next } s' "$config" 2>/dev/null)"
    for key in "${trigger_keys[@]}"; do
        grep -qx "[0-9]*=$key" <<<"$section" || return 1
    done
}

# 기존 파일을 .bak으로 남기고 표준 입력 내용으로 사용자 소유 파일을 씀
write_user_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp -p "$file" "$file.bak"
        echo "Backed up $file to $file.bak"
    fi
    as_user mkdir -p "$(dirname "$file")"
    as_user tee "$file" >/dev/null
}

if pkgs_installed "${pkgs[@]}" && im_selected && profile_has_hangul && trigger_keys_set; then
    skip_done "Korean input (fcitx5-hangul) is already set up for $user"
fi

# 1. 패키지
if pkgs_installed "${pkgs[@]}"; then
    echo "[1/4] ${pkgs[*]} are already installed"
else
    echo "[1/4] Installing ${pkgs[*]}"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"
fi

# 2. 로그인 시 im-config가 fcitx5를 실행하고 입력 모듈 환경 변수(GTK_IM_MODULE 등)를 설정하게 함
if im_selected; then
    echo "[2/4] im-config already selects fcitx5 for $user"
else
    echo "[2/4] Selecting fcitx5 with im-config for $user"
    as_user im-config -n fcitx5
fi

# 실행 중인 fcitx5는 끝날 때 메모리의 입력기 목록으로 profile을 덮어쓰고, 설정은 시작할 때만 읽음
# 그래서 파일을 쓰기 전에 끄고, 쓴 뒤 같은 화면 세션 환경으로 다시 실행함
session_env=()
fcitx_pid="$(pgrep -u "$user" -x fcitx5 | head -n 1 || true)"
if [[ -n "$fcitx_pid" ]] && ! { profile_has_hangul && trigger_keys_set; }; then
    mapfile -t session_env < <(tr '\0' '\n' <"/proc/$fcitx_pid/environ" |
        grep -E '^(DBUS_SESSION_BUS_ADDRESS|WAYLAND_DISPLAY|DISPLAY|XAUTHORITY|XDG_RUNTIME_DIR|XDG_SESSION_TYPE|XDG_CURRENT_DESKTOP)=')
    echo "Stopping the running fcitx5 (pid $fcitx_pid) to update its files"
    kill "$fcitx_pid"
    for _ in {1..10}; do
        kill -0 "$fcitx_pid" 2>/dev/null || break
        sleep 1
    done
    if kill -0 "$fcitx_pid" 2>/dev/null; then
        echo "fcitx5 (pid $fcitx_pid) did not stop within 10 seconds" >&2
        exit 1
    fi
fi

# 3. 입력기 목록: 키보드(비활성 상태)와 한글(전환 시)을 한 그룹에 둠
# 기존 그룹(다른 배열 등)은 덮어쓰므로 .bak으로 남김
if profile_has_hangul; then
    echo "[3/4] Hangul is already in $profile"
else
    # 시스템 키보드 배열(raspi-config가 설정)의 첫 배열을 씀, 없으면 us
    layout="$(
        # shellcheck source=/dev/null
        source /etc/default/keyboard 2>/dev/null || true
        echo "${XKBLAYOUT%%,*}"
    )"
    layout="${layout:-us}"
    echo "[3/4] Writing $profile (keyboard-$layout, hangul)"
    write_user_file "$profile" <<EOF
[Groups/0]
Name=Default
Default Layout=$layout
DefaultIM=hangul

[Groups/0/Items/0]
Name=keyboard-$layout
Layout=

[Groups/0/Items/1]
Name=hangul
Layout=

[GroupOrder]
0=Default
EOF
fi

# 4. 한/영 전환 키: 기존 [Hotkey/TriggerKeys] 절만 바꾸고 나머지 설정은 유지
if trigger_keys_set; then
    echo "[4/4] Trigger keys are already set in $config"
else
    echo "[4/4] Setting trigger keys (${trigger_keys[*]}) in $config"
    new_config="$(
        awk '/^\[/ { s = ($0 == "[Hotkey/TriggerKeys]") } !s' "$config" 2>/dev/null || true
        echo "[Hotkey/TriggerKeys]"
        for i in "${!trigger_keys[@]}"; do
            echo "$i=${trigger_keys[$i]}"
        done
    )"
    write_user_file "$config" <<<"$new_config"
fi

# 위에서 끈 fcitx5를 다시 실행 (-d: 백그라운드)
if ((${#session_env[@]} > 0)); then
    if as_user env "${session_env[@]}" fcitx5 -d >/dev/null 2>&1; then
        echo "Restarted fcitx5 for $user"
        echo "Korean input set up. Restart open apps to type Korean."
    else
        echo "Warning: could not restart fcitx5. Log out and back in to start it." >&2
    fi
else
    echo "Korean input set up. Log out and back in (or reboot) to start fcitx5."
fi
echo "Switch Korean/English with the Hangul key, Shift+Space or Ctrl+Space."
