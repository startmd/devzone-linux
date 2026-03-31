#!/bin/bash
# ==========================================
# devzone-linux INSTALLER
# Copies tools to system locations
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${CYAN}ℹ  ${NC}$1"; }
log_ok()    { echo -e "${GREEN}✅ ${NC}$1"; }
log_warn()  { echo -e "${YELLOW}⚠  ${NC}$1"; }
log_err()   { echo -e "${RED}❌ ${NC}$1"; }
separator() { echo -e "${BOLD}=========================================${NC}"; }

# Root check
if [ "$EUID" -ne 0 ]; then
    log_err "Please run as root: sudo ./install.sh"
    exit 1
fi

ACTUAL_USER="${SUDO_USER:-$USER}"
NEMO_DIR="/home/$ACTUAL_USER/.local/share/nemo/actions"

separator
echo -e "${BOLD}📦 DEVZONE-LINUX INSTALLER${NC}"
separator
echo ""

# --- Verify source files exist ---
log_info "Verifying source files..."

REQUIRED_FILES=("lib.sh" "setup" "make_vhost" "fix_web")
for f in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$f" ]; then
        log_err "Missing: $SCRIPT_DIR/$f"
        exit 1
    fi
    log_ok "Found: $f"
done

echo ""

# --- Create directories ---
log_info "Creating directories..."

install -d /usr/local/bin
install -d /usr/local/lib/devtools

if [ -d "$NEMO_DIR" ]; then
    log_ok "Nemo actions dir exists: $NEMO_DIR"
else
    log_warn "Nemo actions dir not found (Nemo not installed?)"
fi

echo ""

# --- Install lib.sh ---
log_info "Installing lib.sh..."
cp "$SCRIPT_DIR/lib.sh" /usr/local/lib/devtools/lib.sh
chmod 0644 /usr/local/lib/devtools/lib.sh
log_ok "Installed to /usr/local/lib/devtools/lib.sh"

# --- Install CLI tools ---
log_info "Installing CLI tools..."

for tool in setup make_vhost fix_web; do
    src="$SCRIPT_DIR/$tool"
    # setup.sh → /usr/local/bin/setup
    dst="/usr/local/bin/$(echo "$tool" | sed 's/\.sh$//')"
    cp "$src" "$dst"
    chmod +x "$dst"
    log_ok "Installed: $(basename "$dst") → $dst"
done

echo ""

# --- Install Nemo actions ---
if [ -d "$NEMO_DIR" ]; then
    log_info "Installing Nemo actions..."

    # Remove old duplicate actions
    [ -f "$NEMO_DIR/fix_permissions.nemo_action" ] && rm -f "$NEMO_DIR/fix_permissions.nemo_action" && log_ok "Removed old fix_permissions.nemo_action"

    # Install new action
    if [ -f "$SCRIPT_DIR/nemo/fix-permissions.nemo_action" ]; then
        cp "$SCRIPT_DIR/nemo/fix-permissions.nemo_action" "$NEMO_DIR/fix-permissions.nemo_action"
        chown "$ACTUAL_USER":"$ACTUAL_USER" "$NEMO_DIR/fix-permissions.nemo_action"
        log_ok "Installed Nemo action: Fix Web Permissions"
    fi

    echo ""
fi

# --- Summary ---
separator
echo -e "${GREEN}${BOLD}✅ INSTALLATION COMPLETE${NC}"
separator
echo ""
echo -e "  ${CYAN}Installed commands:${NC}"
echo -e "    ${BOLD}sudo setup${NC}          — Interactive dev environment installer"
echo -e "    ${BOLD}sudo make_vhost${NC}     — Add/delete virtual hosts"
echo -e "    ${BOLD}sudo make_vhost list${NC} — List all virtual hosts"
echo -e "    ${BOLD}sudo fix_web${NC}        — Fix web directory permissions"
echo -e "    ${BOLD}sudo fix_web [path]${NC} — Fix specific directory"
echo ""
echo -e "  ${CYAN}Next step:${NC}"
echo -e "    ${BOLD}sudo setup${NC}"
echo ""
separator
