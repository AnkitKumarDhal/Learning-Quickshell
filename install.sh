#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/AnkitKumarDhal/Velox-Q.git"
BRANCH="battery"
INSTALL_DIR="${HOME}/.config/quickshell"
BACKUP_BASE="${HOME}/.config/quickshell.bak"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

info() {
    printf '\033[1;34m==>\033[0m %s\n' "$1"
}

success() {
    printf '\033[1;32m==>\033[0m %s\n' "$1"
}

warn() {
    printf '\033[1;33mwarning:\033[0m %s\n' "$1"
}

error() {
    printf '\033[1;31merror:\033[0m %s\n' "$1" >&2
}

die() {
    error "$1"
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

systemctl_active() {
    systemctl is-active --quiet "$1"
}

has_battery() {
    local path

    for path in /sys/class/power_supply/*; do
        [[ -f "$path/type" ]] || continue

        if [[ "$(cat "$path/type")" == "Battery" ]]; then
            return 0
        fi
    done

    return 1
}

is_velox_installation() {
    [[ -d "${INSTALL_DIR}/.git" ]] || return 1

    local remote
    remote="$(git -C "$INSTALL_DIR" remote get-url origin 2>/dev/null || true)"

    [[ "$remote" == "$REPO_URL" || "$remote" == "git@github.com:AnkitKumarDhal/Velox-Q.git" ]]
}

backup_existing_installation() {
    [[ -e "$INSTALL_DIR" ]] || return 0

    local backup="$BACKUP_BASE"

    if [[ -e "$backup" ]]; then
        local timestamp
        timestamp="$(date '+%Y-%m-%d-%H%M%S')"
        backup="${BACKUP_BASE}-${timestamp}"
    fi

    info "Backing up existing Quickshell configuration"
    mv -- "$INSTALL_DIR" "$backup"
    success "Backup created at $backup"
}

require_arch() {
    [[ -f /etc/arch-release ]] || die "Velox-Q currently supports Arch Linux only."
}

require_not_root() {
    [[ "${EUID}" -ne 0 ]] || die "Do not run this installer as root."
}

install_official_dependencies() {
    local packages=(
        git
        rust
        hyprland
        qt6-base
        qt6-declarative
        pipewire
        wireplumber
        wl-clipboard
        cliphist
        brightnessctl
        awww
    )

    info "Installing required system packages"
    sudo pacman -S --needed "${packages[@]}"
}

install_power_management() {
    if ! has_battery; then
        info "No battery detected; skipping power-management setup"
        return
    fi

    local tlp_installed=false
    local ppd_installed=false
    local tlp_active=false
    local ppd_active=false

    command_exists tlp && tlp_installed=true
    command_exists powerprofilesctl && ppd_installed=true
    systemctl_active tlp.service && tlp_active=true
    systemctl_active power-profiles-daemon.service && ppd_active=true

    if "$tlp_active" && "$ppd_active"; then
        die "Both TLP and power-profiles-daemon are active. Disable one before continuing."
    fi

    if "$tlp_active"; then
        info "TLP is active"

        if ! command_exists tlp-pd || ! command_exists tlpctl; then
            info "Installing tlp-pd"
            sudo pacman -S --needed tlp-pd
        fi

        sudo systemctl enable --now tlp.service
        sudo systemctl enable --now tlp-pd.service

        success "TLP power management configured"
        return
    fi

    if "$ppd_active"; then
        info "power-profiles-daemon is active; leaving existing power management unchanged"
        return
    fi

    if "$tlp_installed"; then
        info "TLP is installed but not active"

        if ! command_exists tlp-pd || ! command_exists tlpctl; then
            info "Installing tlp-pd"
            sudo pacman -S --needed tlp-pd
        fi

        sudo systemctl enable --now tlp.service
        sudo systemctl enable --now tlp-pd.service

        success "TLP power management configured"
        return
    fi

    if "$ppd_installed"; then
        info "power-profiles-daemon is installed but not active"
        sudo systemctl enable --now power-profiles-daemon.service
        success "power-profiles-daemon enabled"
        return
    fi

    info "No power-management backend detected; installing TLP and tlp-pd"

    sudo pacman -S --needed tlp tlp-pd
    sudo systemctl enable --now tlp.service
    sudo systemctl enable --now tlp-pd.service

    success "TLP power management installed"
}

ensure_aur_helper() {
    if command_exists yay; then
        AUR_HELPER="yay"
        return
    fi

    if command_exists paru; then
        AUR_HELPER="paru"
        return
    fi

    warn "No AUR helper was found."

    sudo pacman -S --needed base-devel git

    local temp_dir
    temp_dir="$(mktemp -d)"

    trap 'rm -rf -- "$temp_dir"' RETURN

    info "Bootstrapping yay from the Arch User Repository"

    git clone https://aur.archlinux.org/yay.git "$temp_dir/yay"

    (
        cd "$temp_dir/yay"
        makepkg -si --noconfirm
    )

    command_exists yay || die "yay installation failed."

    AUR_HELPER="yay"
}

install_aur_dependencies() {
    ensure_aur_helper

    info "Installing AUR dependencies"
    "$AUR_HELPER" -S --needed quickshell-git matugen-bin python-pywal16
}

install_repository() {
    if [[ -d "$INSTALL_DIR" ]] && is_velox_installation; then
        info "Existing Velox-Q installation detected"

        if ! git -C "$INSTALL_DIR" diff --quiet ||
            ! git -C "$INSTALL_DIR" diff --cached --quiet ||
            [[ -n "$(git -C "$INSTALL_DIR" status --porcelain)" ]]; then
            die "Your Velox-Q installation has local changes. Commit or stash them before updating."
        fi

        git -C "$INSTALL_DIR" fetch origin "$BRANCH"
        git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH"

        success "Velox-Q updated"
        return
    fi

    if [[ -e "$INSTALL_DIR" ]]; then
        backup_existing_installation
    fi

    info "Installing Velox-Q"

    mkdir -p "$(dirname -- "$INSTALL_DIR")"

    git clone --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"

    success "Velox-Q cloned to $INSTALL_DIR"
}

build_battery_backend() {
    local crate_dir="${INSTALL_DIR}/tools/battery/velox-battery"
    local binary_dir="${INSTALL_DIR}/tools/battery/bin"
    local binary="${binary_dir}/velox-battery"

    [[ -f "${crate_dir}/Cargo.toml" ]] ||
        die "Battery backend source was not found."

    info "Building battery backend"

    (
        cd "$crate_dir"
        cargo build --release
    )

    mkdir -p "$binary_dir"
    install -m 755 "${crate_dir}/target/release/velox-battery" "$binary"

    success "Battery backend installed"
}

configure_tlp_privileges() {
    command_exists tlp || return 0

    if ! systemctl is-active --quiet tlp.service; then
        info "TLP is installed but not active; skipping TLP privilege setup"
        return 0
    fi

    local batteries=()
    local path
    local name

    for path in /sys/class/power_supply/*; do
        [[ -f "$path/type" ]] || continue

        if [[ "$(cat "$path/type")" != "Battery" ]]; then
            continue
        fi

        name="$(basename "$path")"
        batteries+=("$name")
    done

    if ((${#batteries[@]} == 0)); then
        info "No battery detected; skipping TLP charging privileges"
        return 0
    fi

    local sudoers_tmp
    sudoers_tmp="$(mktemp)"

    {
        printf '%s ALL=(root) NOPASSWD:' "$USER"

        local separator=""

        for name in "${batteries[@]}"; do
            printf '%s /usr/bin/tlp setcharge 0 1 %s' "$separator" "$name"
            separator=","
            printf ', /usr/bin/tlp setcharge 0 0 %s' "$name"
        done

        printf '\n'
    } >"$sudoers_tmp"

    if ! sudo visudo -cf "$sudoers_tmp"; then
        rm -f -- "$sudoers_tmp"
        die "Generated TLP sudoers configuration failed validation."
    fi

    info "Installing TLP charging privileges"
    sudo install -m 440 "$sudoers_tmp" /etc/sudoers.d/velox-q
    rm -f -- "$sudoers_tmp"

    success "TLP charging privileges configured"
}

check_prerequisites() {
    require_arch
    require_not_root

    command_exists sudo || die "sudo is required."
}

main() {
    info "Velox-Q installer"

    check_prerequisites

    install_repository
    install_official_dependencies
    install_aur_dependencies
    install_power_management
    build_battery_backend
    configure_tlp_privileges

    success "Velox-Q installation/update complete"
    printf '\n'
    printf 'Configuration: %s\n' "$INSTALL_DIR"
    printf 'Start with:    quickshell\n'
}

main "$@"
