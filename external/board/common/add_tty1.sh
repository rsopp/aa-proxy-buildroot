#!/bin/sh

set -u
set -e

# Add a console on tty1 only if aa-proxy-bap display is not enabled
if [ "${BR2_PACKAGE_AA_PROXY_BAP_DISPLAY:-}" != "y" ] && [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
        sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # console' ${TARGET_DIR}/etc/inittab
fi
