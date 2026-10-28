import json
import os
import subprocess
from pathlib import Path

from gi.repository import Gio, GLib
from gpiozero import DigitalInputDevice


OUTPUT_NAME = "DSI-1"
ROTATION_SENSOR_BCM_GPIO = 17
# ROTATION_SENSOR_BCM_GPIO = 3

TARGET_PANEL = b"raspberrypi,7inch-dsi"

# labwc 설정 파일 (사용자 파일이 없으면 시스템 기본 파일에서 시작)
RC_XML = Path.home() / ".config/labwc/rc.xml"
SYSTEM_RC_XML = Path("/etc/xdg/labwc/rc.xml")

# 트레이 아이콘 (StatusNotifierItem D-Bus 규격)
TRAY_ICON_NAME = "object-rotate-right"
SNI_PATH = "/StatusNotifierItem"
SNI_WATCHER = "org.kde.StatusNotifierWatcher"
SNI_XML = """
<node>
  <interface name="org.kde.StatusNotifierItem">
    <property name="Category" type="s" access="read"/>
    <property name="Id" type="s" access="read"/>
    <property name="Title" type="s" access="read"/>
    <property name="Status" type="s" access="read"/>
    <property name="IconName" type="s" access="read"/>
    <property name="ItemIsMenu" type="b" access="read"/>
    <method name="Activate">
      <arg name="x" type="i" direction="in"/>
      <arg name="y" type="i" direction="in"/>
    </method>
  </interface>
</node>
"""


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


def ensure_touch_mapping() -> None:
    """터치 입력을 DSI-1에 매핑.

    터치가 출력에 매핑되어 있으면 wlr-randr로 화면을 회전할 때
    wlroots가 터치 좌표도 같은 방향으로 함께 회전시킴.
    """
    if RC_XML.exists():
        config = RC_XML.read_text()
    elif SYSTEM_RC_XML.exists():
        config = SYSTEM_RC_XML.read_text()
    else:
        config = '<?xml version="1.0"?>\n<labwc_config>\n</labwc_config>\n'

    if f'mapToOutput="{OUTPUT_NAME}"' in config:
        return

    # 다른 touch 설정이 이미 있으면 덮어쓰지 않음
    if "<touch" in config:
        print(
            f"WARNING: <touch> already exists in {RC_XML}. "
            f'Add mapToOutput="{OUTPUT_NAME}" manually.'
        )
        return

    # 루트 닫는 태그 바로 앞에 추가
    index = config.rfind("</")
    config = (
        config[:index]
        + f'  <touch mapToOutput="{OUTPUT_NAME}" />\n'
        + config[index:]
    )

    RC_XML.parent.mkdir(parents=True, exist_ok=True)
    RC_XML.write_text(config)

    # labwc에 설정 다시 읽도록 요청
    subprocess.run(["labwc", "--reconfigure"], check=False)

    print(f"Touch mapped to {OUTPUT_NAME} in {RC_XML}")


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
    """화면 회전 적용 (터치는 ensure_touch_mapping 매핑에 의해 함께 회전)."""

    current_transform = get_current_transform()

    if current_transform == target_transform:
        print(
            f"{OUTPUT_NAME} already {target_transform}"
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


def toggle_rotation() -> None:
    """현재 상태 기준으로 기본 <-> 180도 토글 (센서 없이 수동 회전용)."""
    if get_current_transform() == "180":
        set_rotation("normal")
    else:
        set_rotation("180")


def start_tray() -> None:
    """패널 트레이에 아이콘 등록. 아이콘을 왼쪽 클릭하면 토글."""
    bus = Gio.bus_get_sync(Gio.BusType.SESSION)
    bus_name = f"org.kde.StatusNotifierItem-{os.getpid()}-1"

    properties = {
        "Category": GLib.Variant("s", "Hardware"),
        "Id": GLib.Variant("s", "auto-rotate"),
        "Title": GLib.Variant("s", "Toggle rotation"),
        "Status": GLib.Variant("s", "Active"),
        "IconName": GLib.Variant("s", TRAY_ICON_NAME),
        # False여야 패널이 왼쪽 클릭 시 메뉴 대신 Activate를 호출함
        "ItemIsMenu": GLib.Variant("b", False),
    }

    def on_method_call(conn, sender, path, iface, method, params, invocation):
        if method == "Activate":
            toggle_rotation()
        invocation.return_value(None)

    def on_get_property(conn, sender, path, iface, prop):
        return properties.get(prop)

    node = Gio.DBusNodeInfo.new_for_xml(SNI_XML)
    bus.register_object(
        SNI_PATH, node.interfaces[0], on_method_call, on_get_property, None
    )
    Gio.bus_own_name_on_connection(
        bus, bus_name, Gio.BusNameOwnerFlags.NONE, None, None
    )

    def on_watcher_appeared(conn, name, owner):
        # 패널이 늦게 뜨거나 재시작되어도 다시 등록됨
        conn.call_sync(
            SNI_WATCHER,
            "/StatusNotifierWatcher",
            SNI_WATCHER,
            "RegisterStatusNotifierItem",
            GLib.Variant("(s)", (bus_name,)),
            None,
            Gio.DBusCallFlags.NONE,
            -1,
            None,
        )
        print("Tray icon registered")

    Gio.bus_watch_name_on_connection(
        bus,
        SNI_WATCHER,
        Gio.BusNameWatcherFlags.NONE,
        on_watcher_appeared,
        None,
    )


sensor.when_activated = update_rotation
sensor.when_deactivated = update_rotation


if __name__ == "__main__":
    print(
        "Rotation sensor started "
        f"(BCM GPIO{ROTATION_SENSOR_BCM_GPIO})"
    )

    if not is_target_display():
        print(
            "Unsupported display"
        )
        exit(1)

    ensure_touch_mapping()

    update_rotation()

    start_tray()

    GLib.MainLoop().run()