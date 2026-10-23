from pathlib import Path


TARGET_PANELS = [
    b"raspberrypi,7inch-dsi",
    b"simple-panel",
]


def get_panel_info() -> bytes:
    panel_path = Path(
        "/proc/device-tree/panel_disp@1/compatible"
    )

    try:
        return panel_path.read_bytes()
    except Exception as exc:
        print(f"패널 정보 읽기 실패: {exc}")
        return b""


def is_target_display() -> bool:
    try:
        panel_type = Path(
            "/proc/device-tree/panel_disp@1/compatible"
        ).read_bytes()

        return any(
            panel in panel_type
            for panel in TARGET_PANELS
        )

    except Exception:
        return False


if __name__ == "__main__":
    panel_info = get_panel_info()

    print(f"Raw panel info: {panel_info}")

    if is_target_display():
        print("지원하는 디스플레이: raspberrypi 7inch DSI")
    else:
        print("지원하지 않는 디스플레이")