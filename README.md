# Fedora Hyprland Setup

A bootstrap script for turning a minimal Fedora 44 installation into a Hyprland development workstation. It installs the desktop stack, development tools, terminal environment, multimedia support, and the repository's Lua-based Hyprland configuration.

This project targets a fresh Fedora installation. It makes system-wide changes and is intentionally opinionated about the desktop, login manager, shell, repositories, and user configuration.

Some of the selected packages and included configurations add a bit of **rice** out of the box, giving the system a clean and cohesive look from the first boot without turning the setup into a heavily themed desktop. The included Hyprland config provides a polished starting point for both the visual style and everyday workflow. It’s intentionally kept relatively lightweight, so you can easily build on the existing rice, swap components, and customize the setup to your own taste.

## What It Installs

### Desktop and session

- Hyprland and the Hyprland Wayland portal
- UWSM, the Universal Wayland Session Manager
- Noctalia Shell, greetd, and Noctalia Greeter
- Xwayland, GTK portals, Polkit, AccountsService, and GNOME Keyring
- Hyprpolkitagent, nwg-look, nwg-displays, and wlsunset

### Applications and terminal tools

- Ghostty, Fish, Starship, tmux, btop, CMatrix, Cava, and Fastfetch
- Wofi application launcher
- Thunar with GVFS, archive, thumbnail, media-tag, and device support
- Yazi
- Chromium and Visual Studio Code
- Git, Git LFS, OpenSSH server, lazygit, fzf, ripgrep, fd, jq, and tree

### Development tools

- GCC, G++, Clang, Clang tools, CMake, Meson, Ninja, and pkg-config
- Rust and Cargo
- Go
- Python, pip, Python development headers
- Node.js and npm

### Media, fonts, and system tools

- Grim and Slurp for screenshots
- MPV, Playerctl, PipeWire multimedia plugins, FFmpeg, and Pavucontrol
- Qt6, qt6ct, Adwaita themes, Matugen, and Cascadia Code NF
- RPM Fusion multimedia packages
- lm_sensors, nethogs, cpupower, upower, and power-profiles-daemon

## External Repositories

The script uses the following external package sources because the required Fedora 44 packages are not all available in the default repositories:

- `lionheartp/Hyprland` COPR for the Hyprland package stack
- `tofik/nwg-shell` COPR for nwg-look and nwg-displays
- Terra for Noctalia Shell and Noctalia Greeter
- RPM Fusion Free and Nonfree for multimedia support
- Microsoft's signed repository for Visual Studio Code
- Flathub is registered for optional Flatpak use, but this script does not install Flatpak applications

The script does not enable the `wl-clip-persist` or Yazi COPRs. Clipboard history uses Fedora packages instead. Terra is restricted to packages matching `noctalia*` after installation. Review and trust these repositories before running the script.

## Requirements

- A fresh or minimally installed Fedora 44 system
- A working network connection
- A normal user account with `sudo` access
- The script must be run as that normal user through `sudo`; do not run it from a root login shell

The script expects `dnf`, `/etc/fedora-release`, `getent`, `systemctl`, and a working `sudo` installation.

## Installation

Install Git and clone the repository as your normal user:

```bash
sudo dnf install -y git
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/nickcisne/fedora-hyprland-setup.git
cd fedora-hyprland-setup
chmod +x fedora-hyprland.sh
```

Review the script and configuration before executing it:

```bash
less fedora-hyprland.sh
find .config -type f -print
```

Run the installer from the repository root:

```bash
sudo ./fedora-hyprland.sh
```

The script asks for confirmation before making changes. Reboot after it completes:

```bash
sudo reboot
```

## System Changes

The installer:

1. Updates Fedora with `dnf upgrade`.
2. Installs RPM Fusion and enables the Hyprland and nwg-shell COPRs.
3. Registers Flatpak and installs the restricted Terra repository for Noctalia Shell and Greeter.
4. Installs the workstation packages listed above.
5. Creates a timestamped backup of the user's existing `~/.config` directory.
6. Copies the repository's `.config` files into the user's `~/.config` directory.
7. Changes the user's login shell to Fish.
8. Adds Starship initialization to Fish when `config.fish` exists.
9. Sets Thunar as the default directory handler.
10. Creates the `greeter` system user and writes `/etc/greetd/config.toml`.
11. Enables the SSH server for inbound remote connections.
12. Disables SDDM if it is installed, enables greetd, and sets `graphical.target` as the default boot target.

If `/etc/greetd/config.toml` already exists, the script leaves it untouched and skips greetd configuration, PAM setup, service enablement, and display-manager changes before continuing with the rest of the installation. It also leaves an active SDDM session running until reboot rather than stopping the display manager underneath the terminal running the installer.

## Repository Structure

```text
fedora-hyprland-setup/
|-- .config/
|   `-- hypr/
|       |-- hyprland.lua
|       |-- keybind.lua
|       `-- startup.lua
|-- fedora-hyprland.sh
|-- LICENSE
`-- README.md
```

### `fedora-hyprland.sh`

The root installer. It performs package installation, repository setup, configuration backup, user configuration deployment, Fish setup, Noctalia Shell startup, and greetd setup. It must be run with `sudo` from a normal user account so `SUDO_USER` identifies the target user.

### `.config/hypr/hyprland.lua`

The Hyprland Lua entrypoint. It loads `startup.lua` and `keybind.lua`, configures window snapping, and disables the default Hyprland logo, splash, and wallpaper. Fedora 44 must provide a Hyprland version with built-in Lua configuration support.

### `.config/hypr/startup.lua`

Defines Wayland, Qt, and Electron environment variables. On Hyprland startup it launches Noctalia Shell, Hyprpolkitagent, GNOME Keyring's secrets component, and the text/image clipboard watchers used by Cliphist. Noctalia provides the desktop panel, launcher, settings interface, and session controls.

### `.config/hypr/keybind.lua`

Defines application, window-management, workspace, screenshot, media, volume, and clipboard bindings. The main bindings include:

| Binding | Action |
| --- | --- |
| `Super+Enter` | Open Ghostty |
| `Super+E` | Open Thunar |
| `Super+C` | Open VS Code |
| `Super+B` | Open Chromium |
| `Super+D` | Toggle the Noctalia launcher |
| `Super+T` | Open Noctalia settings |
| `Super+L` | Lock the session through Noctalia |
| `Super+V` | Open Cliphist clipboard history |
| `Super+Q` | Close the active window |
| `Super+W` | Toggle floating |
| `Super+F` | Toggle fullscreen |
| `Super+1` through `Super+0` | Switch workspaces 1 through 10 |
| `Super+Print` | Save a selected-area screenshot |
| `Alt+Print` | Save a full-display screenshot |
| `Shift+Print` | Copy a selected-area screenshot to the clipboard |

## Clipboard History

Clipboard history is provided by `cliphist` and `wl-clipboard`. The startup configuration stores text and image clipboard contents, and `Super+V` opens a Wofi picker:

```text
copy content -> press Super+V -> select an entry
```

## Backups and Reruns

Before copying repository configuration, the script creates a directory such as:

```text
~/.config-backup-20260918-143000/
```

The repository configuration is overlaid onto `~/.config`; files that are not present in the repository are not deleted. The script is designed primarily for a fresh installation, but the backup allows recovery if it is run on a system with existing configuration.

Rerunning is supported. If an existing greetd configuration is found, it is treated as user-owned state and preserved; the script skips greetd setup while continuing with other installation steps.

## Security Notes

- Inspect the script and `.config` files before running them.
- The installer executes package-manager and system-management commands as root.
- Third-party repositories are a necessary part of the Fedora 44 package selection and should be reviewed independently.
- The installer enables `sshd` for inbound remote access but does not configure passwords, keys, or firewall rules. Review Fedora's SSH and firewall settings before exposing the machine to a network.
- Terra package verification remains enabled for normal package installation. If Terra's initial `terra-release` bootstrap fails only because its repository key is not configured yet, the script retries that one bootstrap transaction with `--nogpgcheck`; it never disables verification for later Terra packages.
- The script does not download and execute arbitrary remote installation scripts.
- The script does not install gaming packages, optional Flatpaks, EasyEffects, or external icon/logo assets.

## Validation

Before pushing or running the script:

```bash
bash -n fedora-hyprland.sh
git diff --check
```

On the target Fedora machine, verify repository/package availability before a full run:

```bash
dnf info hyprland xdg-desktop-portal-hyprland hyprpolkitagent uwsm
dnf info noctalia noctalia-greeter
```

## Attribution

This project was inspired in part by the [minimaLinux](https://github.com/Echilonvibin/minimaLinux) project, which is licensed under the GNU General Public License v3.0. This repository was substantially redesigned for Fedora and is licensed under the MIT License.

## License

This project is available under the MIT License. See [LICENSE](LICENSE).
