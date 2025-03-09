#!/bin/sh

# Created By: Javier Pacheco - javier@jpacheco.xyz
# Created On: 01/02/25
# Project: Custom Void Linux jpachecoxyz iso.

doas ./mkiso.sh -- \
    -a "x86_64-musl" \
    -C "live.shell=/bin/zsh" \
    -g "sudo dhcpcd base-system" \
    -I includedir \
    -o ./void-jpachecoxyz.iso \
    -p "NetworkManager opendoas git stow zsh hyprland hyprland-protocols xdg-desktop-portal-hyprland wayland Waybar fastfetch bat tofi foot seatd mesa-dri eza wbg jq" \
    -r "https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-musl" \
    -S "seatd" \
    -T "VoidJP" \
    -v "linux6.10"
