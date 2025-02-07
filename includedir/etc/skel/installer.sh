#!/usr/bin/env bash

# Created By: Javier Pacheco - jpacheco@cock.li
# Created On: 28/01/25
# Project: Void linux custom packages

doas xbps-install -Suy \
    base-minimal \
    bash \
    bat \
    bc \
    bgs \
    bluez \
    brightnessctl \
    curl \
    dejavu-fonts-ttf \
    dhcpcd \
    direnv \
    dracut \
    e2fsprogs \
    emacs-pgtk \
    enchant2-devel \
    ethtool \
    eudev \
    eza \
    fastfetch \
    ffmpeg \
    file \
    firefox \
    font-ibm-plex-otf \
    foot \
    fzf \
    gcc \
    git \
    grim \
    gvfs \
    htop \
    hugo \
    hunspell \
    hunspell-devel \
    iproute2 \
    iputils \
    jq \
    psmisc \
    kbd \
    kmod \
    lazygit \
    less \
    libnotify \
    libnotify-devel \
    linux-firmware \
    linux-firmware-network \
    linux5.10 \
    mako \
    man-pages \
    mesa-dri \
    mpv \
    ncurses \
    neovim \
    nodejs \
    noto-fonts-emoji \
    NetworkManager \
    imv \
    opendoas \
    openssh \
    os-prober \
    p7zip \
    pciutils \
    polkit \
    procps-ng \
    pulseaudio \
    python3-pipx \
    ripgrep \
    seatd \
    slurp \
    stow \
    swappy \
    swww \
    tectonic \
    tofi \
    tomb \
    traceroute \
    unzip \
    usbutils \
    util-linux \
    vim \
    Waybar \
    wf-recorder \
    xfsprogs \
    xrdb \
    xz \
    yazi \
    yt-dlp \
    zathura-pdf-poppler \
    zsh

doas ln -s /usr/bin/doas /usr/bin/sudo

# Determine whether to use doas or sudo
if command -v doas >/dev/null 2>&1; then
    ELEVATE="doas"
elif command -v sudo >/dev/null 2>&1; then
    ELEVATE="sudo"
else
    echo "Neither 'doas' nor 'sudo' is available. Please install one of them to continue."
    exit 1
fi

# Install required packages
$ELEVATE xbps-install -Suy dbus seatd polkit mesa-dri foot tofi

# Ensure the ~/.local/src/ directory exists
cd $HOME
[ -d "$HOME/.local/src/" ] && echo "~/.local/src/ folder exists in the system." || mkdir -p "$HOME/.local/src/"
cd "$HOME/.local/src"

# Clone necessary repositories
git clone https://github.com/void-linux/void-packages --depth 1
git clone https://github.com/Makrennel/hyprland-void --depth 1

# Prepare the build environment
cd void-packages
./xbps-src binary-bootstrap

# Copy files from hyprland-void
cd ../hyprland-void
cat common/shlibs >> ../void-packages/common/shlibs
cp -r srcpkgs/* ../void-packages/srcpkgs

# Build Hyprland and related packages
cd ../void-packages
./xbps-src pkg hyprland
./xbps-src pkg xdg-desktop-portal-hyprland
./xbps-src pkg hyprland-protocols

# Install the built packages
$ELEVATE xbps-install -y -R hostdir/binpkgs hyprland
$ELEVATE xbps-install -y -R hostdir/binpkgs hyprland-protocols
$ELEVATE xbps-install -y -R hostdir/binpkgs xdg-desktop-portal-hyprland

# Enable necessary services
$ELEVATE ln -s /etc/sv/dbus /var/service
$ELEVATE ln -s /etc/sv/polkitd /var/service
$ELEVATE ln -s /etc/sv/seatd /var/service

# Add the user to the _seatd group
$ELEVATE usermod -aG _seatd "$USER"

# Clean up the cloned repositories
rm -rf "$HOME/.local/src/void-packages"
rm -rf "$HOME/.local/src/hyprland-void"
echo "Folders have been removed from the system."
