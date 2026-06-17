#!/usr/bin/env bash
# Removes the Mac baseline (Microsoft Office only) listed in the Brewfile.
#
# HOW TO RUN (from the repo folder):
#   bash mac/uninstall.sh
#
# Mac devices only require Microsoft Office, so this is intentionally small.

set -uo pipefail

# Put brew on PATH (Apple Silicon vs Intel)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found - nothing installed by this tool to remove."
  exit 0
fi

CASK="microsoft-office"

echo "This will UNINSTALL: $CASK"
read -r -p "Continue? (y/N) " answer
case "$answer" in
  y|Y|yes|YES) ;;
  *) echo "Cancelled. Nothing was removed."; exit 0 ;;
esac

if brew list --cask "$CASK" >/dev/null 2>&1; then
  brew uninstall --cask "$CASK" && echo "==> Uninstalled $CASK"
else
  echo "==> $CASK not present - nothing to do"
fi
