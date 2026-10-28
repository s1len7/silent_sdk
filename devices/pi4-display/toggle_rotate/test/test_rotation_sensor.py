from gpiozero import DigitalInputDevice
from signal import pause


SENSOR_PIN = 17  # BCM GPIO17 = 물리 핀 11번
# SENSOR_PIN = 3  # BCM GPIO17 = 물리 핀 5번


sensor = DigitalInputDevice(
    SENSOR_PIN,
    pull_up=True
)


def sensor_changed():
    value = sensor.value

    if value:
        print("Sensor value: 1 -> Rotation: 180 degree")
    else:
        print("Sensor value: 0 -> Rotation: 0 degree")


sensor.when_activated = sensor_changed
sensor.when_deactivated = sensor_changed

print("Rotation sensor test started")
pause()