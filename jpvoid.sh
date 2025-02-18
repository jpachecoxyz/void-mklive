#!/bin/sh

# Created By: Javier Pacheco - javier@jpacheco.xyz
# Created On: 01/02/25
# Project: Custom Void Linux jpachecoxyz iso.

doas ./mkiso.sh -- \
    -I includedir \
    -o ./void-jpachecoxyz.iso \
    -T "VoidJP" \
    -p "NetworkManager opendoas git stow" \
    -g "sudo dhcpcd base-system" \
    -v "linux6.10"
