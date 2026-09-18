#!/usr/bin/env bash

set -Eeuo pipefail

HYPRLAND_COPR="lionheartp/Hyprland"
NWG_SHELL_COPR="tofik/nwg-shell"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

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

run_as_user() {
    sudo -u "$ACTUAL_USER" "$@"
}

if [[ $EUID -ne 0 ]]; then
    die "Run this script with sudo from your normal user account."
fi

if ! command -v dnf >/dev/null 2>&1; then
    die "dnf was not found. This script is intended for Fedora."
fi

if [[ ! -f /etc/fedora-release ]]; then
    die "This script is intended for Fedora."
fi

if [[ -z "${SUDO_USER:-}" || "$SUDO_USER" == "root" ]]; then
    die "SUDO_USER could not be determined. Run: sudo ./setup.sh"
fi

ACTUAL_USER="$SUDO_USER"
ACTUAL_USER_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"

[[ -n "$ACTUAL_USER_HOME" ]] ||
    die "Could not determine home directory for $ACTUAL_USER."

if [[ ! -d "$SCRIPT_DIR/.config" ]]; then
    die "No .config directory found. Run this from the repository root."
fi

if [[ ! -d "$SCRIPT_DIR/.config/hypr" ]]; then
    die "No .config/hypr directory found."
fi

GREETD_CONFIG="/etc/greetd/config.toml"

if [[ -e "$GREETD_CONFIG" || -L "$GREETD_CONFIG" ]]; then
    die "Existing greetd configuration found at $GREETD_CONFIG. Refusing to overwrite it."
fi

cat <<EOF

===============================================================================
 Fedora + Hyprland Development Workstation
===============================================================================

Desktop:
  Hyprland, Noctalia Shell, Noctalia Greeter, greetd

Terminal:
  Ghostty, Fish, Starship, tmux, btop, cmatrix, cava
  fzf, ripgrep, fd, jq, tree, lazygit

File management:
  Thunar, GVFS, Tumbler, File Roller, Yazi

Browser:
  Chromium

Development:
  VS Code, Git, Clang, CMake, Meson, Ninja
  Rust, Go, Python, Node.js

System:
  Flatpak, RPM Fusion, multimedia support
  monitoring and power-management tools

This script will:
  - update Fedora
    - enable the Hyprland COPR and restricted Terra repository
  - install the workstation software listed above
  - back up the existing ~/.config directory
  - install the repository configuration
  - configure Fish, Starship, Yazi, Thunar, and greetd
  - set graphical.target as the default boot target

===============================================================================

EOF

read -r -p "Continue? [y/N] " ANSWER

case "$ANSWER" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 0 ;;
esac

log "Updating Fedora"

dnf upgrade -y

log "Installing base packages"

dnf install -y \
    git \
    git-lfs \
    openssh-server \
    curl \
    wget \
    ca-certificates \
    gnupg2 \
    gcc \
    gcc-c++ \
    make \
    openssl \
    tar \
    unzip \
    zip \
    rsync

log "Installing RPM Fusion"

dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

log "Enabling Hyprland COPR"

dnf -y copr enable "$HYPRLAND_COPR"

log "Enabling nwg-shell COPR"

dnf -y copr enable "$NWG_SHELL_COPR"

log "Installing Flatpak"

dnf install -y flatpak

flatpak remote-add \
    --if-not-exists \
    flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

log "Installing Terra repository for Noctalia"

if rpm -q terra-release >/dev/null 2>&1; then
    log "Terra release package is already installed; skipping bootstrap"
else
    TERRA_BOOTSTRAP_LOG="$(mktemp)"
    if ! dnf install -y \
        --repofrompath "terra,https://repos.fyralabs.com/terra\$releasever" \
        terra-release 2>&1 | tee "$TERRA_BOOTSTRAP_LOG"; then
        if grep -Eiq 'does not have openpgp keys configured|signature verification failed' "$TERRA_BOOTSTRAP_LOG"; then
            warn "Terra's bootstrap package does not publish a usable key to DNF yet. Retrying only terra-release without signature checking."
            dnf install -y \
                --nogpgcheck \
                --repofrompath "terra,https://repos.fyralabs.com/terra\$releasever" \
                terra-release
        else
            rm -f "$TERRA_BOOTSTRAP_LOG"
            die "Terra bootstrap failed for a reason other than its initial key configuration."
        fi
    fi
    rm -f "$TERRA_BOOTSTRAP_LOG"
fi

TERRA_REPO="/etc/yum.repos.d/terra.repo"

if [[ ! -f "$TERRA_REPO" ]]; then
    die "Terra is installed, but its repository file was not found at $TERRA_REPO."
fi

if ! grep -q '^includepkgs=' "$TERRA_REPO"; then
    sed -i \
        '/^\[terra\]/a includepkgs=noctalia*' \
        "$TERRA_REPO"
fi

log "Installing Hyprland desktop"

dnf install -y \
    dbus \
    polkit \
    accountsservice \
    greetd \
    noctalia \
    noctalia-greeter \
    hyprland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    xorg-x11-server-Xwayland \
    mesa-dri-drivers \
    mesa-vulkan-drivers \
    uwsm \
    hyprpolkitagent \
    gnome-keyring \
    nwg-look \
    nwg-displays \
    wlsunset \
    xdg-user-dirs \
    cliphist \
    wl-clipboard \
    wofi

log "Installing graphical file-management stack"

dnf install -y \
    thunar \
    thunar-media-tags-plugin \
    thunar-shares-plugin \
    thunar-vcs-plugin \
    thunar-volman \
    thunar-archive-plugin \
    tumbler \
    file-roller \
    gvfs \
    gvfs-afc \
    gvfs-mtp \
    gvfs-smb \
    poppler-glib \
    ffmpegthumbnailer \
    freetype \
    unrar \
    unzip \
    p7zip \
    p7zip-plugins \
    ntfs-3g \
    dosfstools \
    exfatprogs \
    gnome-disk-utility \
    adwaita-icon-theme

log "Installing terminal environment"

dnf install -y \
    ghostty \
    fish \
    fastfetch \
    cava \
    btop \
    cmatrix \
    tmux \
    fzf \
    ripgrep \
    fd-find \
    jq \
    tree \
    lazygit

log "Installing Yazi"

dnf install -y \
    yazi \
    --setopt=install_weak_deps=False

log "Installing development tools"

dnf install -y \
    clang \
    clang-tools-extra \
    cmake \
    meson \
    ninja-build \
    pkgconf \
    golang \
    rust \
    cargo \
    python3 \
    python3-pip \
    python3-devel \
    nodejs \
    npm

log "Installing Chromium"

dnf install -y chromium

log "Installing multimedia support"

dnf install -y \
    pavucontrol \
    playerctl \
    grim \
    slurp \
    mpv \
    gst-plugins-good \
    gst-plugins-ugly \
    gst-libav \
    ffmpeg

log "Installing fonts, themes and Qt support"

dnf install -y \
    qt6-qtbase \
    qt6-qtwebsockets \
    qt6ct \
    adw-gtk-theme \
    adw-gtk3-theme \
    adwaita-icon-theme \
    google-noto-emoji-fonts \
    dejavu-sans-fonts \
    cascadia-code-nf-fonts \
    matugen

log "Installing monitoring and power-management tools"

dnf install -y \
    lm_sensors \
    nethogs \
    cpupower \
    upower \
    power-profiles-daemon

log "Configuring VS Code repository"

rpm --import https://packages.microsoft.com/keys/microsoft.asc

cat > /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

dnf makecache
dnf install -y code

log "Installing Starship"

if dnf info starship >/dev/null 2>&1; then
    dnf install -y starship
else
    warn "Starship is not available from the configured Fedora repositories."
fi

log "Configuring Fish"

FISH_PATH="$(command -v fish || true)"

if [[ -n "$FISH_PATH" ]]; then
    CURRENT_SHELL="$(getent passwd "$ACTUAL_USER" | cut -d: -f7)"

    if [[ "$CURRENT_SHELL" != "$FISH_PATH" ]]; then
        usermod -s "$FISH_PATH" "$ACTUAL_USER"
    fi
fi

log "Backing up existing configuration"

CONFIG_DIR="$ACTUAL_USER_HOME/.config"
BACKUP_DIR="$ACTUAL_USER_HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$CONFIG_DIR"

if [[ -n "$(find "$CONFIG_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
    mkdir -p "$BACKUP_DIR"

    cp -a \
        "$CONFIG_DIR"/. \
        "$BACKUP_DIR"/

    chown \
        -R \
        "$ACTUAL_USER:$ACTUAL_USER" \
        "$BACKUP_DIR"

    echo "Configuration backup: $BACKUP_DIR"
fi

log "Installing repository configuration"

cp -a \
    "$SCRIPT_DIR/.config/." \
    "$CONFIG_DIR/"

chown \
    -R \
    "$ACTUAL_USER:$ACTUAL_USER" \
    "$CONFIG_DIR"

log "Configuring Starship"

FISH_CONFIG="$ACTUAL_USER_HOME/.config/fish/config.fish"

if [[ -f "$FISH_CONFIG" ]] &&
   command -v starship >/dev/null 2>&1; then

    if ! grep -Fq 'starship init fish' "$FISH_CONFIG"; then
        cat >> "$FISH_CONFIG" <<'EOF'

starship init fish | source
EOF
    fi

    chown \
        "$ACTUAL_USER:$ACTUAL_USER" \
        "$FISH_CONFIG"
fi

log "Configuring Yazi"

YAZI_FISH_DIR="$ACTUAL_USER_HOME/.config/fish/functions"
YAZI_FISH="$YAZI_FISH_DIR/yazi.fish"

mkdir -p "$YAZI_FISH_DIR"

if [[ ! -f "$YAZI_FISH" ]]; then
    cat > "$YAZI_FISH" <<'EOF'
function yazi
    set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"

    if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end

    rm -f -- "$tmp"
end
EOF

    chown \
        "$ACTUAL_USER:$ACTUAL_USER" \
        "$YAZI_FISH"
fi

log "Setting Thunar as directory handler"

run_as_user \
    xdg-mime default thunar.desktop inode/directory \
    || true

log "Enabling AccountsService"

systemctl enable accounts-daemon

log "Enabling SSH server"

systemctl enable --now sshd

log "Configuring greetd"

GREETER_USER="greeter"
GREETER_STATE="/var/lib/noctalia-greeter"

if ! id -u "$GREETER_USER" >/dev/null 2>&1; then
    useradd \
        --system \
        --shell /usr/sbin/nologin \
        --home-dir "$GREETER_STATE" \
        "$GREETER_USER"
fi

mkdir -p "$GREETER_STATE"

chown \
    -R \
    "$GREETER_USER:$GREETER_USER" \
    "$GREETER_STATE"

NOCTALIA_SESSION="$(command -v noctalia-greeter-session || true)"

if [[ -z "$NOCTALIA_SESSION" ]]; then
    die "noctalia-greeter-session was not installed correctly."
fi

mkdir -p "/etc/greetd"

cat > "$GREETD_CONFIG" <<EOF
[terminal]
vt = 1

[default_session]
command = "$NOCTALIA_SESSION"
user = "$GREETER_USER"
EOF

if [[ -x /usr/share/noctalia-greeter/setup_greetd_pam.sh ]]; then
    /usr/share/noctalia-greeter/setup_greetd_pam.sh || \
        warn "Noctalia PAM setup returned an error."
fi

if systemctl list-unit-files sddm.service --no-legend 2>/dev/null | grep -q '^sddm\.service'; then
    log "Disabling SDDM before enabling greetd"
    systemctl disable sddm

    if systemctl is-active --quiet sddm; then
        warn "SDDM is currently active and will remain running until reboot."
        warn "Do not start greetd manually from this graphical session."
    fi
fi

systemctl enable greetd
systemctl set-default graphical.target

cat <<EOF

===============================================================================
 Setup complete
===============================================================================

Installed:
  Hyprland
    Noctalia Shell and Greeter
  greetd
  Ghostty
  Fish
  Starship
  Chromium
  Thunar
  Yazi
  VS Code
  Git
  Clang
  CMake
  Meson
  Ninja
  Rust
  Go
  Python
  Node.js
  btop
  cmatrix
  cava
  tmux
  lazygit
  fzf
  ripgrep
  fd
  jq
  tree

Hyprland Lua keybindings and startup configuration were installed.

Reboot before testing the graphical session.

===============================================================================

EOF