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

check_prerequisites() {
    require_arch
    require_not_root

    command_exists sudo || die "sudo is required."
}

main() {
    info "Velox-Q installer"

    check_prerequisites

    install_official_dependencies
    install_aur_dependencies
    install_repository
    build_battery_backend

    success "Velox-Q installation/update complete"
    printf '\n'
    printf 'Configuration: %s\n' "$INSTALL_DIR"
    printf 'Start with:    quickshell\n'
}

main "$@"
