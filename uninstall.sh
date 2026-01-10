#!/bin/bash
#
# Chopshop Uninstaller
#
# Usage: ~/.chopshop/uninstall.sh
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

CHOPSHOP_DIR="$HOME/.chopshop"
BIN_DIR="$HOME/.local/bin"
CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"

info() { echo -e "→ $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

echo ""
echo -e "${BOLD}Chopshop Uninstaller${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Confirm
read -p "Remove chopshop and all its files? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Remove bin scripts
info "Removing bin scripts..."
rm -f "$BIN_DIR/chopshop-load"
rm -f "$BIN_DIR/chopshop-validate"
success "Removed bin scripts"

# Remove Claude commands
info "Removing Claude Code skills..."
if [ -L "$CLAUDE_COMMANDS_DIR/chopshop" ]; then
    rm "$CLAUDE_COMMANDS_DIR/chopshop"
    success "Removed skills symlink"
elif [ -d "$CLAUDE_COMMANDS_DIR/chopshop" ]; then
    rm -rf "$CLAUDE_COMMANDS_DIR/chopshop"
    success "Removed skills directory"
fi

# Remove main directory
info "Removing chopshop directory..."
if [ -d "$CHOPSHOP_DIR" ]; then
    rm -rf "$CHOPSHOP_DIR"
    success "Removed $CHOPSHOP_DIR"
fi

echo ""
echo -e "${GREEN}Chopshop uninstalled.${NC}"
echo ""
echo "Note: Session data in project .chopshop/ directories was not removed."
echo ""
