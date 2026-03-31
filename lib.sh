#!/bin/bash
# ==========================================
# devzone-linux shared library
# Source this file in all devzone scripts
# ==========================================

# --- State Variables ---
INSTALLER="${INSTALLER:-apt}"
WEB_SERVER="${WEB_SERVER:-}"
ACTUAL_USER="${ACTUAL_USER:-}"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# --- Logging ---
log_info()  { echo -e "${CYAN}ℹ  ${NC}$1"; }
log_ok()    { echo -e "${GREEN}✅ ${NC}$1"; }
log_warn()  { echo -e "${YELLOW}⚠  ${NC}$1"; }
log_err()   { echo -e "${RED}❌ ${NC}$1"; }
log_step()  { echo -e "\n${BOLD}${BLUE}━━━ $1 ━━━${NC}"; }
log_item()  { echo -e "   ${CYAN}→${NC} $1"; }

# --- Privilege Check ---
root_check() {
    if [ "$EUID" -ne 0 ]; then
        log_err "Please run as root: sudo $0"
        exit 1
    fi
}

# --- Resolve Actual User ---
get_user() {
    ACTUAL_USER="${SUDO_USER:-$USER}"
    if [ -z "$ACTUAL_USER" ] || [ "$ACTUAL_USER" = "root" ]; then
        log_err "Could not determine non-root user. Run with sudo."
        exit 1
    fi
    echo "$ACTUAL_USER"
}

# --- Yes/No Prompt ---
ask_permission() {
    local prompt="$1"
    local default="${2:-N}"
    local hint="[y/N]"
    [[ "$default" == "Y" || "$default" == "y" ]] && hint="[Y/n]"

    local prompt_str
    printf -v prompt_str "${CYAN}❓ ${prompt} ${hint}: ${NC}"
    read -rp "$prompt_str" response
    response="${response:-$default}"
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# --- Single Select Menu ---
# Usage: ask_select "Pick one:" "Option A" "Option B" "Option C"
# Result stored in SELECTED (index 0-based)
SELECTED=""
ask_select() {
    local prompt="$1"
    shift
    local options=("$@")
    local count=${#options[@]}

    echo -e "${CYAN}❓ ${prompt}${NC}"
    for i in "${!options[@]}"; do
        echo -e "   $((i+1))) ${options[$i]}"
    done

    while true; do
        local ask_prompt
        printf -v ask_prompt "   ${BOLD}Enter choice (1-${count}): ${NC}"
        read -rp "$ask_prompt" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
            SELECTED=$((choice - 1))
            return 0
        fi
        log_warn "Invalid choice. Enter a number between 1 and ${count}."
    done
}

# --- Multi Select Menu ---
# Usage: ask_multi "Pick items:" "Item A" "Item B" "Item C"
# Result stored in SELECTED_ITEMS (array of indices 0-based)
SELECTED_ITEMS=()
ask_multi() {
    local prompt="$1"
    shift
    local options=("$@")
    local count=${#options[@]}
    local selected=()

    echo -e "${CYAN}❓ ${prompt}${NC}"
    for i in "${!options[@]}"; do
        echo -e "   $((i+1))) ${options[$i]}"
    done
    echo -e "   ${YELLOW}0) Done / Confirm selection${NC}"

    while true; do
        local ask_prompt
        printf -v ask_prompt "   ${BOLD}Enter number (or 0 to confirm): ${NC}"
        read -rp "$ask_prompt" choice
        if [ "$choice" = "0" ]; then
            break
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
            local idx=$((choice - 1))
            # Check if already selected
            local already=false
            for s in "${selected[@]}"; do
                [ "$s" = "$idx" ] && already=true && break
            done
            if $already; then
                log_warn "'${options[$idx]}' already selected."
            else
                selected+=("$idx")
                log_ok "Added: ${options[$idx]}"
            fi
        else
            log_warn "Invalid choice. Enter a number between 0 and ${count}."
        fi
    done

    SELECTED_ITEMS=("${selected[@]}")
}

# --- Detect Web Server ---
detect_web_server() {
    if [ -n "$WEB_SERVER" ]; then
        echo "$WEB_SERVER"
        return
    fi

    if systemctl is-active --quiet nginx 2>/dev/null; then
        WEB_SERVER="nginx"
    elif systemctl is-active --quiet apache2 2>/dev/null; then
        WEB_SERVER="apache"
    elif command -v apache2 &>/dev/null; then
        WEB_SERVER="apache"
    elif command -v nginx &>/dev/null; then
        WEB_SERVER="nginx"
    else
        WEB_SERVER="none"
    fi
    echo "$WEB_SERVER"
}

# --- Check if command/package is installed ---
is_installed() {
    local target="$1"
    # Check command in PATH
    if command -v "$target" &>/dev/null; then
        return 0
    fi
    # Check dpkg
    if dpkg -l "$target" 2>/dev/null | grep -q "^ii"; then
        return 0
    fi
    # Check flatpak
    if flatpak list 2>/dev/null | grep -q "$target"; then
        return 0
    fi
    # Check snap
    if snap list 2>/dev/null | grep -q "$target"; then
        return 0
    fi
    return 1
}

# --- Detect and validate installer backend ---
detect_installer() {
    case "$INSTALLER" in
        apt)
            if ! command -v apt &>/dev/null; then
                log_err "apt not found on this system."
                return 1
            fi
            ;;
        flatpak)
            if ! command -v flatpak &>/dev/null; then
                log_warn "flatpak not found. Installing..."
                apt update -qq && apt install -y flatpak
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
            fi
            ;;
        snap)
            if ! command -v snap &>/dev/null; then
                # Check if Linux Mint snap blocker exists
                if [ -f /etc/apt/preferences.d/nosnap.pref ]; then
                    log_warn "Linux Mint blocks snap by default."
                    if ask_permission "Remove snap blocker and install snapd?"; then
                        mv /etc/apt/preferences.d/nosnap.pref /etc/apt/preferences.d/nosnap.pref.bak
                        apt update -qq
                    else
                        log_err "Cannot use snap without removing the blocker."
                        return 1
                    fi
                fi
                apt update -qq && apt install -y snapd
                systemctl enable --now snapd.socket
                # Snap needs /snap in PATH
                if ! echo "$PATH" | grep -q "/snap/bin"; then
                    export PATH="$PATH:/snap/bin"
                fi
            fi
            ;;
        *)
            log_err "Unknown installer: $INSTALLER (use: apt, flatpak, snap)"
            return 1
            ;;
    esac
}

# --- Unified Install Function ---
# Usage: install_app "Display Name" "apt_pkg" "flatpak_id" "snap_name"
# Use "skip" for unsupported methods, "official" for custom installer
install_app() {
    local name="$1"
    local apt_pkg="$2"
    local flatpak_id="$3"
    local snap_name="$4"

    case "$INSTALLER" in
        apt)
            if [ "$apt_pkg" = "official" ]; then
                log_warn "$name: requires official installer (see docs)"
                return 2
            elif [ "$apt_pkg" = "skip" ]; then
                log_warn "$name: not available via apt, skipping"
                return 2
            else
                apt install -y $apt_pkg
            fi
            ;;
        flatpak)
            if [ "$flatpak_id" = "skip" ] || [ -z "$flatpak_id" ]; then
                log_warn "$name: not available via flatpak, skipping"
                return 2
            else
                flatpak install -y flathub "$flatpak_id"
            fi
            ;;
        snap)
            if [ "$snap_name" = "skip" ] || [ -z "$snap_name" ]; then
                log_warn "$name: not available via snap, skipping"
                return 2
            else
                snap install "$snap_name" --classic
            fi
            ;;
    esac
}

# --- Add APT Repository ---
# Usage: add_apt_repo "name" "deb_line" "gpg_key_url" "keyring_name"
add_apt_repo() {
    local name="$1"
    local repo_line="$2"
    local key_url="$3"
    local keyring="$4"

    local keyring_path="/etc/apt/keyrings/${keyring}"

    if [ -f "$keyring_path" ]; then
        log_item "$name repo already configured"
        return 0
    fi

    log_item "Adding $name repository..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "$key_url" | gpg --dearmor -o "$keyring_path"
    chmod 0644 "$keyring_path"
    echo "$repo_line" > "/etc/apt/sources.list.d/${name}.list"
    apt update -qq
}

# --- Run Command with Logging ---
run_cmd() {
    local desc="$1"
    shift
    log_item "$desc"
    "$@" 2>/dev/null
    local code=$?
    if [ $code -eq 0 ]; then
        log_ok "$desc — done"
    else
        log_warn "$desc — exited with code $code"
    fi
    return $code
}

# --- Enable Systemd Service ---
enable_svc() {
    local svc="$1"
    if systemctl list-unit-files | grep -q "$svc"; then
        systemctl enable --now "$svc" 2>/dev/null
        log_ok "Service $svc enabled and started"
    else
        log_warn "Service $svc not found"
    fi
}

# --- Patch PHP ini Value ---
# Usage: set_php_ini "/etc/php/8.2/apache2/php.ini" "memory_limit" "512M"
set_php_ini() {
    local ini_file="$1"
    local key="$2"
    local value="$3"

    if [ ! -f "$ini_file" ]; then
        return 1
    fi

    # Check if key exists (commented or uncommented)
    if grep -qE "^;?\s*${key}\s*=" "$ini_file"; then
        # Uncomment and set value
        sed -i "s|^;\?\s*${key}\s*=.*|${key} = ${value}|" "$ini_file"
    else
        # Key doesn't exist, append under [PHP] section
        sed -i "/^\[PHP\]/a ${key} = ${value}" "$ini_file"
    fi
}

# --- Ensure directory exists with ownership ---
ensure_dir() {
    local dir="$1"
    local owner="${2:-$ACTUAL_USER}"
    local group="${3:-www-data}"

    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
    chown -R "$owner":"$group" "$dir"
}

# --- Check if running on Linux Mint / Ubuntu ---
get_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# --- Print separator ---
separator() {
    echo -e "${BOLD}=========================================${NC}"
}
