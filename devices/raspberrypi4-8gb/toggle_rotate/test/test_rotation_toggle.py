import json
import subprocess
import sys

STATE_FILE = "/tmp/dsi1_rotate_state.txt"
OUTPUT_NAME = "DSI-1"


def get_current_transform() -> str:
    """wlr-randr JSON 출력을 파싱하여 DSI-1의 현재 transform 상태를 반환합니다."""
    try:
        result = subprocess.run(
            ["wlr-randr", "--json"],
            capture_output=True,
            text=True,
            check=True,
        )
        data = json.loads(result.stdout)
        for output in data:
            if output.get("name") == OUTPUT_NAME:
                return output.get("transform", "normal")
    except Exception:
        pass
    return "normal"


def set_rotation(target_transform: str) -> None:
    """wlr-randr를 통해 화면을 회전하고, wl-mirror/wlr-randr 기반 터치 매핑을 적용합니다."""
    # 1. 화면 회전 적용
    subprocess.run(
        ["wlr-randr", "--output", OUTPUT_NAME, "--transform", target_transform],
        check=True,
    )

    # 2. 터치 좌표 매핑 설정
    # Wayfire 설정(wayfire.ini)에 지정하거나, LIBINPUT 디바이스 설정을 적용합니다.
    # Wayland 환경에서 특정 출력에 터치스크린을 고정/매핑하는 명령어 실행
    try:
        # 터치 좌표 매핑 처리
        if target_transform == "180":
            transform_val = "180"
        else:
            transform_val = "normal"

        # wayfirectl이 설치된 경우 라인 입력 적용
        subprocess.run(
            [
                "wayfirectl",
                "set",
                f"input/touch_device_{OUTPUT_NAME}_transform",
                transform_val,
            ],
            capture_output=True,
        )
    except Exception:
        pass


def main() -> None:
    current_transform = get_current_transform()

    # 기본 -> 180도 -> 기본 토글 처리
    if current_transform == "normal":
        target = "180"
    else:
        target = "normal"

    set_rotation(target)
    print(f"{OUTPUT_NAME} 상태 변경 완료: {current_transform} -> {target}")


if __name__ == "__main__":
    main()