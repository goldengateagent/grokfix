#!/usr/bin/env bash
set -euo pipefail

# Install grokfix into ~/.grokfix/bin.

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

# Add a PATH export to the shell rc if ~/.grokfix/bin is not in PATH.
case ":$PATH:" in
  *":$HOME/.grokfix/bin:"*)
    echo "~/.grokfix/bin already on PATH"
    ;;
  *)
    case "$(basename "${SHELL:-}")" in
      zsh)  RC="$HOME/.zshrc" ;;
      bash) RC="$HOME/.bashrc" ;;
      *)    RC="$HOME/.profile" ;;
    esac
    touch "$RC"
    if ! grep -qs '\.grokfix/bin' "$RC"; then
      printf '\n# grokfix\nexport PATH="$HOME/.grokfix/bin:$PATH"\n' >> "$RC"
      echo "added PATH export to $RC"
    fi
    ;;
esac

echo "installed $DEST"
echo "restart your shell (or source your rc) to pick up the PATH change"
