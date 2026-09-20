#!/usr/bin/env bash
set -euo pipefail

# Install the xai-grok-pager binary into ~/.grokfix/bin.

SRC="../grok-build/target/release/xai-grok-pager"
DEST_DIR="$HOME/.grokfix/bin"
DEST="$DEST_DIR/grokfix"

# Resolve script directory so the source path works from any cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/../grok-build/target/release/xai-grok-pager"

if [[ ! -f "$SRC" ]]; then
  echo "error: binary not found at $SRC" >&2
  echo "build it first: (cd ../grok-build && cargo build --release)" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
install -m 755 "$SRC" "$DEST"

# Add ~/.grokfix/bin to PATH in shell rc if not already there.
add_path_line() {
  local rc="$1"
  touch "$rc"
  if ! grep -qs 'GROKFIX_BIN\|\.grokfix/bin' "$rc"; then
    printf '\n# xai-grok-pager binary\nexport GROKFIX_BIN="$HOME/.grokfix/bin"\ncase ":$PATH:" in\n  *":$GROKFIX_BIN:"*) ;;\n  *) export PATH="$GROKFIX_BIN:$PATH" ;;\nesac\n' >> "$rc"
    echo "added PATH entry to $rc"
  fi
}

case "$(basename "${SHELL:-}")" in
  zsh)  RC="$HOME/.zshrc" ;;
  bash) RC="$HOME/.bashrc" ;;
  *)    RC="$HOME/.profile" ;;
esac

add_path_line "$RC"

echo "installed $DEST"
echo "restart your shell (or source your rc) to pick up the PATH change"
