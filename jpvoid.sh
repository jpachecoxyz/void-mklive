#!/bin/sh

# Created By: Javier Pacheco - javier@jpacheco.xyz
# Created On: 01/02/25
# Project: Custom Void Linux jpachecoxyz iso.

doas ./mkiso.sh -- \
    -a "x86_64-musl" \
    -I includedir \
    -o ./void-jpachecoxyz.iso \
    -T "VoidJP" \
    -p "NetworkManager opendoas git stow zsh Hyprland wayland" \
    -r "https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-musl" \

    -g "sudo dhcpcd base-system" \
    -v "linux6.10"
