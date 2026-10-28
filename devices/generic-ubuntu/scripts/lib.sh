#!/usr/bin/env bash
# common functions for generic-ubuntu modules
SKIP_EXIT=3

skip_done() {
    echo "$1, skipped"
    exit "$SKIP_EXIT"
}

pkgs_installed() {
    local p
    for p in "$@"; do
        dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q 'install ok installed' || return 1
    done
    return 0
}
