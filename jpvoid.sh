#!/bin/sh

# Created By: Javier Pacheco - javier@jpacheco.xyz
# Created On: 01/02/25
# Project: Custom Void Linux jpachecoxyz iso.

doas ./mkiso.sh -- \
    -I includedir \
    -o ~/Downloads/void-jpachecoxyz.iso \
    -T "VoidJP" \
    -p "NetworkManager opendoas" \
    -g "sudo" \
    -v "linux5.10"
