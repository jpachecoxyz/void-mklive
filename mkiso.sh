#!/bin/bash

set -eu

. ./lib.sh

PROGNAME=$(basename "$0")
ARCH=$(uname -m)
IMAGES="base"
TRIPLET=
REPO=
DATE=$(date -u +%Y%m%d)

usage() {
	cat <<-EOH
	Usage: $PROGNAME [options ...] [-- mklive options ...]

	Wrapper script around mklive.sh for several standard flavors of live images.
	Adds void-installer and other helpful utilities to the generated images.

	OPTIONS
	 -a <arch>     Set architecture (or platform) in the image
	 -b <variant>  One of base, enlightenment, xfce, mate, cinnamon, gnome, kde,
	               lxde, lxqt, or xfce-wayland (default: base). May be specified multiple times
	               to build multiple variants
	 -d <date>     Override the datestamp on the generated image (YYYYMMDD format)
	 -t <arch-date-variant>
	               Equivalent to setting -a, -b, and -d
	 -r <repo>     Use this XBPS repository. May be specified multiple times
	 -h            Show this help and exit
	 -V            Show version and exit

	Other options can be passed directly to mklive.sh by specifying them after the --.
	See mklive.sh -h for more details.
	EOH
}

while getopts "a:b:d:t:hr:V" opt; do
case $opt in
    a) ARCH="$OPTARG";;
    b) IMAGES="$OPTARG";;
    d) DATE="$OPTARG";;
    r) REPO="-r $OPTARG $REPO";;
    t) TRIPLET="$OPTARG";;
    V) version; exit 0;;
    h) usage; exit 0;;
    *) usage >&2; exit 1;;
esac
done
shift $((OPTIND - 1))

INCLUDEDIR=$(mktemp -d)
trap "cleanup" INT TERM

cleanup() {
    rm -rf "$INCLUDEDIR"
}

include_installer() {
    if [ -x installer.sh ]; then
        MKLIVE_VERSION="$(PROGNAME='' version)"
        installer=$(mktemp)
        sed "s/@@MKLIVE_VERSION@@/${MKLIVE_VERSION}/" installer.sh > "$installer"
        install -Dm755 "$installer" "$INCLUDEDIR"/usr/bin/void-installer
        rm "$installer"
    else
        echo installer.sh not found >&2
        exit 1
    fi
}

build_variant() {
    variant="$1"
    shift
    IMG=void-jpachecoxyz.iso

    # el-cheapo installer is unsupported on arm because arm doesn't install a kernel by default
    # and to work around that would add too much complexity to it
    # thus everyone should just do a chroot install anyways
    WANT_INSTALLER=no
    case "$ARCH" in
        x86_64*|i686*)
            GRUB_PKGS="grub-i386-efi grub-x86_64-efi"
            GFX_PKGS="xorg-video-drivers"
            GFX_WL_PKGS="mesa-dri"
            WANT_INSTALLER=yes
            TARGET_ARCH="$ARCH"
            ;;
        aarch64*)
            GRUB_PKGS="grub-arm64-efi"
            GFX_PKGS="xorg-video-drivers"
            GFX_WL_PKGS="mesa-dri"
            TARGET_ARCH="$ARCH"
            ;;
        asahi*)
            GRUB_PKGS="asahi-base asahi-scripts grub-arm64-efi"
            GFX_PKGS="mesa-asahi-dri"
            GFX_WL_PKGS="mesa-asahi-dri"
            KERNEL_PKG="linux-asahi"
            TARGET_ARCH="aarch64${ARCH#asahi}"
            if [ "$variant" = xfce ]; then
                info_msg "xfce is not supported on asahi, switching to xfce-wayland"
                variant="xfce-wayland"
            fi
            ;;
    esac

    A11Y_PKGS="espeakup brltty"
    PKGS="dialog cryptsetup lvm2 mdadm $A11Y_PKGS $GRUB_PKGS"
    FONTS="font-misc-misc terminus-font dejavu-fonts-ttf"
    WAYLAND_PKGS="$GFX_WL_PKGS $FONTS"
    SERVICES=""

    LIGHTDM_SESSION=''

    case $variant in
        base)
            SERVICES="$SERVICES NetworkManager dbus wpa_supplicant"
        ;;
        *)
            >&2 echo "Unknown variant $variant"
            exit 1
        ;;
    esac

    if [ "$WANT_INSTALLER" = yes ]; then
        include_installer
    else
        mkdir -p "$INCLUDEDIR"/usr/bin
        printf "#!/bin/sh\necho 'void-installer is not supported on this live image'\n" > "$INCLUDEDIR"/usr/bin/void-installer
        chmod 755 "$INCLUDEDIR"/usr/bin/void-installer
    fi

    ./mklive.sh -a "$TARGET_ARCH" -o "$IMG" -p "$PKGS" -S "$SERVICES" -I "$INCLUDEDIR" \
        ${KERNEL_PKG:+-v $KERNEL_PKG} ${REPO} "$@"

	cleanup
}

if [ ! -x mklive.sh ]; then
    echo mklive.sh not found >&2
    exit 1
fi

if [ -n "$TRIPLET" ]; then
    IFS=: read -r ARCH DATE VARIANT _ < <( echo "$TRIPLET" | sed -Ee 's/^(.+)-([0-9rc]+)-(.+)$/\1:\2:\3/' )
    build_variant "$VARIANT" "$@"
else
    for image in $IMAGES; do
        build_variant "$image" "$@"
    done
fi
