import json
import subprocess
from pathlib import Path
from signal import pause

from gpiozero import DigitalInputDevice


OUTPUT_NAME = "DSI-1"
ROTATION_SENSOR_BCM_GPIO = 17
# ROTATION_SENSOR_BCM_GPIO = 3

TARGET_PANEL = b"raspberrypi,7inch-dsi"


sensor = DigitalInputDevice(
    ROTATION_SENSOR_BCM_GPIO,
    pull_up=True,
)


def is_target_display() -> bool:
    """지원하는 DSI 패널인지 확인."""
    try:
        panel_type = Path(
            "/proc/device-tree/panel_disp@1/compatible"
        ).read_bytes()

        return TARGET_PANEL in panel_type

    except Exception:
        return False


def get_current_transform() -> str:
    """wlr-randr JSON 출력을 파싱하여 현재 transform 상태 반환."""
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
    """화면 및 터치 좌표 회전 적용."""

    current_transform = get_current_transform()

    if current_transform == target_transform:
        print(
            f"{OUTPUT_NAME} 이미 {target_transform} 상태"
        )
        return

    subprocess.run(
        [
            "wlr-randr",
            "--output",
            OUTPUT_NAME,
            "--transform",
            target_transform,
        ],
        check=True,
    )

    try:
        if target_transform == "180":
            transform_val = "180"
        else:
            transform_val = "normal"

        subprocess.run(
            [
                "wayfirectl",
                "set",
                (
                    f"input/touch_device_"
                    f"{OUTPUT_NAME}_transform"
                ),
                transform_val,
            ],
            capture_output=True,
        )

    except Exception:
        pass

    print(
        f"{OUTPUT_NAME}: "
        f"{current_transform} -> {target_transform}"
    )


def update_rotation() -> None:
    """센서 상태에 따라 회전 방향 결정."""

    sensor_value = sensor.value

    if sensor_value:
        target = "180"
        degree = 180
    else:
        target = "normal"
        degree = 0

    print(
        f"Sensor={sensor_value}, "
        f"Rotation={degree} degree"
    )

    set_rotation(target)


sensor.when_activated = update_rotation
sensor.when_deactivated = update_rotation


if __name__ == "__main__":
    print(
        "Rotation sensor started "
        f"(BCM GPIO{ROTATION_SENSOR_BCM_GPIO})"
    )

    if not is_target_display():
        print(
            "지원하지 않는 디스플레이"
        )
        exit(1)

    update_rotation()

    pause()