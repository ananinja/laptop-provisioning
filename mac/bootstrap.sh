#!/usr/bin/env bash
# One-shot Mac provisioning. Installs Homebrew (if missing) then the Brewfile baseline.
#
# HOW TO RUN (admin pastes this one line on a fresh Mac):
#   curl -fsSL https://raw.githubusercontent.com/ananinja/laptop-provisioning/main/mac/bootstrap.sh | bash
#
# Note: Microsoft Office installs the apps; license activation is per-user and stays manual.

set -euo pipefail

OWNER="ananinja"
BREWFILE_URL="https://raw.githubusercontent.com/${OWNER}/laptop-provisioning/main/mac/Brewfile"

echo "==> Laptop provisioning starting"

# 1. Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 2. Put brew on PATH for this session (Apple Silicon vs Intel)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# 3. Download the Brewfile and install everything in it
tmp="$(mktemp)"
echo "==> Downloading Brewfile"
curl -fsSL "$BREWFILE_URL" -o "$tmp"

echo "==> Installing apps (this can take several minutes)"
brew bundle --file="$tmp"

echo ""
echo "==> Done. Reminder: sign into Microsoft 365 to activate Office."
