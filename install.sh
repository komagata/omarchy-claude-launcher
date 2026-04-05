#!/usr/bin/env bash
# install.sh — Install claude-launcher for omarchy/Hyprland users.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$SCRIPT_DIR/bin/claude-launcher"
BIN_DEST="$HOME/.local/bin/claude-launcher"
HYPR_BINDINGS="$HOME/.config/hypr/bindings.conf"
KEYBIND_LINE='bindd = SUPER, I, Claude project launcher, exec, claude-launcher'

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

echo "claude-launcher installer"
echo "========================="
echo ""

# 1. Check dependencies
echo "Checking dependencies..."
missing=()
for cmd in tmux walker hyprctl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing+=("$cmd")
  fi
done

# A terminal emulator (alacritty, ghostty, foot, kitty)
term_found=""
for t in "${TERMINAL:-}" alacritty ghostty foot kitty; do
  [[ -n "$t" ]] || continue
  if command -v "$t" >/dev/null 2>&1; then
    term_found="$t"
    break
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  red "  Missing required commands: ${missing[*]}"
  echo "  Please install them first. On omarchy these are usually present by default."
  exit 1
fi
if [[ -z "$term_found" ]]; then
  red "  No supported terminal emulator found (tried: alacritty, ghostty, foot, kitty)"
  echo "  Please install one or set \$TERMINAL."
  exit 1
fi
green "  OK (terminal: $term_found)"

# 2. Copy or symlink the script
echo ""
read -rp "Install bin/claude-launcher to $BIN_DEST? [Y/n] " ans
if [[ "${ans,,}" == "n" ]]; then
  echo "  Skipped."
else
  mkdir -p "$HOME/.local/bin"
  if [[ -e "$BIN_DEST" ]]; then
    yellow "  $BIN_DEST already exists."
    read -rp "  Overwrite? [y/N] " ow
    if [[ "${ow,,}" != "y" ]]; then
      echo "  Kept existing file."
    else
      cp "$BIN_SRC" "$BIN_DEST"
      chmod +x "$BIN_DEST"
      green "  Overwritten."
    fi
  else
    cp "$BIN_SRC" "$BIN_DEST"
    chmod +x "$BIN_DEST"
    green "  Installed."
  fi
fi

# 3. Add Hyprland keybind
echo ""
if [[ -f "$HYPR_BINDINGS" ]]; then
  if grep -qF "claude-launcher" "$HYPR_BINDINGS"; then
    yellow "  Keybind for claude-launcher already present in $HYPR_BINDINGS; skipping."
  else
    # Warn if SUPER,I is already bound to something else
    if grep -qE '^\s*bind[dne]?\s*=\s*SUPER\s*,\s*I\b' "$HYPR_BINDINGS"; then
      yellow "  SUPER+I appears to already be bound in $HYPR_BINDINGS."
      echo "  Review the file and edit the keybind manually. Suggested line:"
      echo ""
      echo "    $KEYBIND_LINE"
      echo ""
    else
      read -rp "Append SUPER+I keybind to $HYPR_BINDINGS? [Y/n] " ans
      if [[ "${ans,,}" == "n" ]]; then
        echo "  Skipped. Add this line manually:"
        echo "    $KEYBIND_LINE"
      else
        {
          echo ""
          echo "# claude-launcher"
          echo "$KEYBIND_LINE"
        } >> "$HYPR_BINDINGS"
        green "  Appended. Reload Hyprland with: hyprctl reload"
      fi
    fi
  fi
else
  yellow "  $HYPR_BINDINGS not found. Add this line to your Hyprland config manually:"
  echo "    $KEYBIND_LINE"
fi

# 4. Configuration hint
echo ""
green "Done!"
echo ""
echo "Optional configuration (add to your shell profile):"
echo ""
echo "  export CLAUDE_LAUNCHER_WORKS_DIR=\"\$HOME/Works\""
echo "  export CLAUDE_LAUNCHER_DEFAULT_NS=\"yourname\"     # optional, see README"
echo "  export CLAUDE_LAUNCHER_TERMINAL=\"$term_found\""
echo ""
echo "Try it by pressing SUPER+I (after 'hyprctl reload')."
