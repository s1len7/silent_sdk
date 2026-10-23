#!/bin/bash

# https://docs.magicmirror.builders/configuration/autostart.html

cd /home/silent/MagicMirror || exit 1
DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 node --run start
