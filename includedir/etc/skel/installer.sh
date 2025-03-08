#!/usr/bin/env bash

# Created By: Javier Pacheco - jpacheco@cock.li
# Created On: 28/01/25
# Project: Void linux custom packages post-installation

set -e  # Exit on error
set -o pipefail  # Exit if any command in a pipeline fails

PACKAGE_LIST="packages.txt"
LOG_FILE="/tmp/install_script.log"

# Function to log and display messages
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Function to handle errors
error_exit() {
    log "❌ Error: $1"
    exit 1
}

# Check for required tools
command -v doas >/dev/null 2>&1 || error_exit "doas is not installed! Please install it first."

# Check if the package list file exists
[[ -f "$PACKAGE_LIST" ]] || error_exit "$PACKAGE_LIST not found!"

log "📦 Starting package installation..."

# Read and install packages
while IFS= read -r package; do
    [[ -z "$package" || "$package" =~ ^# ]] && continue  # Skip empty and commented lines

    log "➡ Installing: $package"
    doas xbps-install -Suy "$package" || error_exit "Failed to install $package"
done < "$PACKAGE_LIST"

# Symlink doas as sudo if not already linked
if [[ ! -L "/usr/bin/sudo" ]]; then
    log "🔗 Creating symlink: doas -> sudo"
    doas ln -s /usr/bin/doas /usr/bin/sudo || error_exit "Failed to create symlink for sudo"
fi

# Install required system packages
REQUIRED_PACKAGES="dbus seatd polkit mesa-dri foot tofi"
log "📦 Installing required packages: $REQUIRED_PACKAGES"
doas xbps-install -Suy $REQUIRED_PACKAGES || error_exit "Failed to install required packages"

# Install Hyprland
HYPRLAND_CONF="/etc/xbps.d/hyprland-packages.conf"
if [[ ! -f "$HYPRLAND_CONF" ]]; then
    log "📝 Adding Hyprland repository"
    echo "repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-musl" | doas tee "$HYPRLAND_CONF" > /dev/null
fi

log "🌟 Installing Hyprland and dependencies"
doas xbps-install -Suy hyprland hyprland-protocols xdg-desktop-portal-hyprland || error_exit "Failed to install Hyprland"

# Enable necessary services
SERVICES=("dbus" "polkitd" "seatd" "bluetoothd" "sshd" "libvirt" "virtlockd" "virtlogd")
for service in "${SERVICES[@]}"; do
    SERVICE_PATH="/var/service/$service"
    if [[ ! -L "$SERVICE_PATH" ]]; then
        log "🔧 Enabling service: $service"
        doas ln -s "/etc/sv/$service" "$SERVICE_PATH" || error_exit "Failed to enable $service"
    fi
done

# Add user to _seatd group
log "👤 Adding $USER to _seatd group"
doas usermod -aG _seatd "$USER" || error_exit "Failed to add $USER to _seatd"
doas usermod -aG libvirt "$USER" || error_exit "Failed to add $USER to libvirt"
doas usermod -aG kvm "$USER" || error_exit "Failed to add $USER to kvm"

log "✅ Installation completed successfully!"
