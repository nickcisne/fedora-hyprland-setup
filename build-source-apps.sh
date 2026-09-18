#!/usr/bin/env bash

set -Eeuo pipefail

GHOSTTY_REPOSITORY="https://github.com/ghostty-org/ghostty.git"
YAZI_REPOSITORY="https://github.com/sxyazi/yazi.git"
SOURCE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/fedora-hyprland-setup/sources"
GHOSTTY_SOURCE="$SOURCE_ROOT/ghostty"
YAZI_SOURCE="$SOURCE_ROOT/yazi"
LOCAL_PREFIX="${HOME}/.local"

log() {
    printf '\n\033[1;36m==> %s\033[0m\n' "$*"
}

warn() {
    printf '\n\033[1;33mWARNING: %s\033[0m\n' "$*" >&2
}

die() {
    printf '\n\033[1;31mERROR: %s\033[0m\n' "$*" >&2
    exit 1
}

if [[ $EUID -eq 0 ]]; then
    die "Run this script as your normal user, not with sudo."
fi

if [[ ! -f /etc/fedora-release ]]; then
    die "This script is intended for Fedora."
fi

command -v git >/dev/null 2>&1 || die "git is required."
command -v sudo >/dev/null 2>&1 || die "sudo is required."

sudo -v

log "Installing source-build dependencies"

sudo dnf install -y \
    blueprint-compiler \
    gtk4-devel \
    gtk4-layer-shell-devel \
    libadwaita-devel \
    gettext \
    pkgconf \
    zig \
    rust \
    cargo \
    gcc \
    make \
    file

mkdir -p "$SOURCE_ROOT" "$LOCAL_PREFIX/bin"

clone_or_update() {
    local repository="$1"
    local destination="$2"

    if [[ -d "$destination/.git" ]]; then
        log "Updating $(basename "$destination") source"
        git -C "$destination" pull --ff-only
    else
        log "Cloning $(basename "$destination") source"
        git clone "$repository" "$destination"
    fi
}

clone_or_update "$GHOSTTY_REPOSITORY" "$GHOSTTY_SOURCE"
clone_or_update "$YAZI_REPOSITORY" "$YAZI_SOURCE"

log "Building and installing Ghostty"

if ! command -v zig >/dev/null 2>&1; then
    die "zig was not found after installing the build dependencies."
fi

(
    cd "$GHOSTTY_SOURCE"
    zig build -p "$LOCAL_PREFIX" -Doptimize=ReleaseFast
)

log "Building and installing Yazi"

if ! command -v cargo >/dev/null 2>&1; then
    die "cargo was not found after installing the build dependencies."
fi

(
    cd "$YAZI_SOURCE"
    cargo xtask build
    install -Dm755 target/release/yazi "$LOCAL_PREFIX/bin/yazi"
    install -Dm755 target/release/ya "$LOCAL_PREFIX/bin/ya"
)

cat <<EOF

===============================================================================
 Source builds complete
===============================================================================

Ghostty and Yazi were installed under:
  $LOCAL_PREFIX

Ensure these directories are on your PATH:
  $LOCAL_PREFIX/bin

Source checkouts:
  $GHOSTTY_SOURCE
  $YAZI_SOURCE

The Hyprland default terminal remains Kitty. This script does not change the
Hyprland configuration.

===============================================================================

EOF
