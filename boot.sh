#!/usr/bin/env bash
set -euo pipefail

# Simple color helpers
info()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" >&2; }

# 1. Check if GitHub CLI is already installed
if command -v gh >/dev/null 2>&1; then
  ok "GitHub CLI (gh) is already installed: $(gh --version | head -n1)"
  exit 0
fi

info "GitHub CLI (gh) not found; installing…"

# 2. Ensure we're on a Debian/Ubuntu-like system (has apt)
if ! command -v apt >/dev/null 2>&1; then
  error "This script is intended for Ubuntu/Debian systems with apt."
  exit 1
fi

# 3. Ensure wget is available
if ! command -v wget >/dev/null 2>&1; then
  info "wget not found; installing wget…"
  sudo apt update
  sudo apt install -y wget
fi

# 4. Set up GitHub CLI official apt repo and keyring
info "Configuring GitHub CLI apt repository…"

sudo mkdir -p -m 755 /etc/apt/keyrings
tmpkey="$(mktemp)"
wget -nv -O "$tmpkey" https://cli.github.com/packages/githubcli-archive-keyring.gpg
sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null <"$tmpkey"
rm -f "$tmpkey"
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

sudo mkdir -p -m 755 /etc/apt/sources.list.d
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null

# 5. Install gh
info "Updating apt cache…"
sudo apt update

info "Installing GitHub CLI (gh)…"
sudo apt install -y gh

# 6. Verify installation
if command -v gh >/dev/null 2>&1; then
  ok "GitHub CLI installed successfully: $(gh --version | head -n1)"
else
  error "GitHub CLI installation appears to have failed."
  exit 1
fi
