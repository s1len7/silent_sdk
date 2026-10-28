#!/usr/bin/env bash
# 패널(작업표시줄) 런처에 전원 끄기 아이콘 추가 스크립트
# 라즈베리파이 아이콘 메뉴의 Shutdown(Shutdown Options 창)과 같은 프로그램인
# pishutdown을 Trixie 패널 런처 목록(~/.config/wf-panel-pi/wf-panel-pi.ini의 launchers)에 추가
# Trixie의 launchers 항목은 명령어로 해석되기도 하고 .desktop 파일 이름으로 해석되기도 하는데,
# 명령어 이름과 .desktop 이름이 같은 pishutdown을 쓰면 두 방식 모두 동작함
# 예전 형식의 launcher_000001= 항목은 건드리지 않음 (Trixie 지원 형식은 launchers= 목록)

# 사용법: sudo bash scripts/setup_shutdown_shortcut.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

# sudo로 실행해도 실제 로그인 사용자의 홈에 적용
user_name="${SUDO_USER:-$(whoami)}"
user_home="$(getent passwd "$user_name" | cut -d: -f6)"

entry="pishutdown"   # 명령어 = .desktop 이름(확장자 제외)이 같은 프로그램
desktop_id="${entry}.desktop"
user_apps="$user_home/.local/share/applications"
panel_ini="$user_home/.config/wf-panel-pi/wf-panel-pi.ini"
system_ini="/etc/xdg/wf-panel-pi/wf-panel-pi.ini"

# .desktop 검색 순서 (wf-panel-pi launcher와 같음: 사용자 → raspi-ui-overrides → 시스템)
find_desktop() {
    local dir
    for dir in "$user_apps" /usr/share/raspi-ui-overrides/applications /usr/share/applications; do
        [[ -f "$dir/$desktop_id" ]] && { printf '%s\n' "$dir/$desktop_id"; return 0; }
    done
    return 1
}

# 공백으로 구분된 launchers 목록에 항목이 있으면 0 (토큰 단위 비교, 와일드카드 확장 없이)
in_list() {
    local tok
    local -a toks
    [[ -z "$1" ]] && return 1
    read -ra toks <<< "$1"
    for tok in "${toks[@]}"; do
        [[ "$tok" == "$2" ]] && return 0
    done
    return 1
}

launchers_value=""
if [[ -f "$panel_ini" ]]; then
    # launchers 줄이 없어도 스크립트가 끝나지 않게 grep 대신 awk 사용 (set -o pipefail)
    launchers_value="$(tr -d '\r' < "$panel_ini" | awk '/^launchers=/ { sub(/^launchers=/, ""); print; exit }')"
fi

# .desktop을 찾을 수 있고 launchers 목록에 있으면 건너뜀
if find_desktop >/dev/null && in_list "$launchers_value" "$entry"; then
    skip_done "Shutdown launcher icon is already set up"
fi

# pishutdown이 설치돼 있지 않으면 설치 (Trixie의 Shutdown 메뉴가 쓰는 프로그램)
if ! pkgs_installed pishutdown; then
    echo "Installing pishutdown"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y pishutdown
fi

# 시스템 어디에도 .desktop 파일이 없으면 사용자 applications에 새로 만듦
# (pishutdown 패키지의 pishutdown.desktop을 기반으로 이름만 Shutdown으로 바꿈)
if ! find_desktop >/dev/null; then
    echo "Creating $user_apps/$desktop_id"
    mkdir -p "$user_apps"
    cat > "$user_apps/$desktop_id" <<EOF
[Desktop Entry]
Type=Application
Name=Shutdown
Comment=Shutdown and logout options
Categories=Applications
Icon=system-shutdown
Exec=$entry
EOF
fi

# launchers 목록에 항목 추가 (여러 번 실행해도 중복 없음)
mkdir -p "$(dirname "$panel_ini")"
if [[ ! -f "$panel_ini" ]]; then
    # 사용자 파일이 없으면 시스템 기본 파일에서 시작 (toggle_rotate의 labwc rc.xml와 같은 방식)
    if [[ -f "$system_ini" ]]; then
        echo "Starting $panel_ini from $system_ini"
        tr -d '\r' < "$system_ini" > "$panel_ini"
    else
        printf '[panel]\n' > "$panel_ini"
    fi
fi

work="$(mktemp)"
# 원본이 Windows에서 편집된 경우를 대비해 CR 제거
tr -d '\r' < "$panel_ini" > "$work"
launchers_value="$(awk '/^launchers=/ { sub(/^launchers=/, ""); print; exit }' "$work")"

if ! in_list "$launchers_value" "$entry"; then
    if grep -q '^launchers=' "$work"; then
        # 기존 launchers 줄 끝에 추가
        sed -i "s/^launchers=.*/launchers=$launchers_value $entry/" "$work"
    elif grep -q '^\[panel\]' "$work"; then
        # launchers 줄이 없으면 [panel] 다음에 새로 추가
        sed -i "/^\[panel\]/a launchers=$entry" "$work"
    else
        printf '[panel]\nlaunchers=%s\n' "$entry" >> "$work"
    fi
fi

# cp 대신 cat으로 써서 기존 파일 권한을 유지
cat "$work" > "$panel_ini"
rm -f "$work"

chown -R "$user_name:" "$(dirname "$panel_ini")"
# 시스템에 .desktop이 이미 있으면 사용자 applications 폴더를 만들지 않았을 수 있음
if [[ -d "$user_apps" ]]; then
    chown -R "$user_name:" "$user_apps"
fi

echo "Added $entry to panel launchers in $panel_ini"
echo "The shutdown icon opens the same Shutdown Options window as the Raspberry Pi menu Shutdown."
echo "If the icon does not appear, log in again to refresh the panel."
