#!/bin/bash
#
# Chopshop Installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/lavallee/chopshop/main/install.sh | bash
#
# Or clone and run locally:
#   ./install.sh
#
# Options:
#   CHOPSHOP_DIR    Where to install chopshop (default: ~/.chopshop)
#   CHOPSHOP_REPO   Git repo URL (default: https://github.com/lavallee/chopshop.git)
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
CHOPSHOP_DIR="${CHOPSHOP_DIR:-$HOME/.chopshop}"
CHOPSHOP_REPO="${CHOPSHOP_REPO:-https://github.com/lavallee/chopshop.git}"
BIN_DIR="$HOME/.local/bin"
CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"

info() { echo -e "${BLUE}→${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1" >&2; exit 1; }

echo ""
echo -e "${BOLD}Chopshop Installer${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Check dependencies
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
info "Checking dependencies..."

if ! command -v git &> /dev/null; then
    error "git is required but not installed"
fi

if ! command -v jq &> /dev/null; then
    warn "jq is not installed (required for chopshop-load)"
    warn "Install with: brew install jq (macOS) or apt install jq (Linux)"
fi

success "Dependencies OK"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Install or update chopshop
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [ -d "$CHOPSHOP_DIR" ]; then
    info "Updating existing installation..."
    cd "$CHOPSHOP_DIR"
    git pull --quiet origin main 2>/dev/null || git pull --quiet
    success "Updated chopshop"
else
    info "Installing chopshop to $CHOPSHOP_DIR..."

    # If running from a local clone, copy instead of git clone
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/bin/chopshop-load" ]; then
        info "Installing from local directory..."
        mkdir -p "$CHOPSHOP_DIR"
        cp -r "$SCRIPT_DIR"/* "$CHOPSHOP_DIR/"
        success "Copied chopshop files"
    else
        git clone --quiet "$CHOPSHOP_REPO" "$CHOPSHOP_DIR"
        success "Cloned chopshop"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Install bin scripts
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
info "Installing bin scripts to $BIN_DIR..."

mkdir -p "$BIN_DIR"

for script in "$CHOPSHOP_DIR"/bin/*; do
    if [ -f "$script" ]; then
        name=$(basename "$script")
        ln -sf "$script" "$BIN_DIR/$name"
        chmod +x "$script"
    fi
done

success "Installed: chopshop-load, chopshop-validate"

# Check if BIN_DIR is in PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    warn "$BIN_DIR is not in your PATH"
    echo ""
    echo "Add this to your shell config (~/.bashrc, ~/.zshrc, etc.):"
    echo ""
    echo -e "  ${BOLD}export PATH=\"\$PATH:$BIN_DIR\"${NC}"
    echo ""
    ADD_TO_PATH=true
else
    success "bin directory is in PATH"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Install Claude Code skills
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
info "Installing Claude Code skills..."

mkdir -p "$CLAUDE_COMMANDS_DIR"

# Symlink the chopshop commands directory
if [ -L "$CLAUDE_COMMANDS_DIR/chopshop" ]; then
    rm "$CLAUDE_COMMANDS_DIR/chopshop"
fi

if [ -d "$CLAUDE_COMMANDS_DIR/chopshop" ]; then
    warn "Existing chopshop commands found, backing up..."
    mv "$CLAUDE_COMMANDS_DIR/chopshop" "$CLAUDE_COMMANDS_DIR/chopshop.backup.$(date +%s)"
fi

ln -sf "$CHOPSHOP_DIR/.claude/commands/chopshop" "$CLAUDE_COMMANDS_DIR/chopshop"

success "Installed skills: /chopshop/triage, /chopshop/architect, /chopshop/planner"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Summary
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}${BOLD}Chopshop installed successfully!${NC}"
echo ""
echo "Installed to: $CHOPSHOP_DIR"
echo ""
echo -e "${BOLD}Quick Start:${NC}"
echo ""
echo "  # In any project directory with a vision doc:"
echo "  /chopshop/triage VISION.md"
echo ""
echo "  # Or run the pipeline:"
echo "  /chopshop/triage → /chopshop/architect → /chopshop/planner"
echo ""
echo -e "${BOLD}Helper Scripts:${NC}"
echo ""
echo "  chopshop-load <plan.jsonl>   # Load plan into beads"
echo "  chopshop-validate            # Validate beads state"
echo ""

if [ "${ADD_TO_PATH:-false}" = true ]; then
    echo -e "${YELLOW}Don't forget to add ~/.local/bin to your PATH!${NC}"
    echo ""
fi

# Check for beads
if ! command -v bd &> /dev/null; then
    echo -e "${YELLOW}Note:${NC} Beads CLI (bd) not found."
    echo "Install for task management: brew tap steveyegge/beads && brew install beads"
    echo ""
fi

echo "Documentation: $CHOPSHOP_DIR/CLAUDE.md"
echo ""
