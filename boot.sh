#!/usr/bin/env bash
set -euo pipefail

# Simple color helpers
info()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" >&2; }

# Track what needs to be installed
NEED_GH=false
NEED_CHEZMOI=false
NEED_LAZYGIT=false
NEED_CARGO=false
NEED_BOB=false
NEED_FZF=false
NEED_YAZI=false
NEED_RIPGREP=false
NEED_FD=false
NEED_GIT=false
NEED_1PASSWORD=false

# 1. Check if GitHub CLI is already installed
if command -v gh >/dev/null 2>&1; then
  ok "GitHub CLI (gh) is already installed: $(gh --version | head -n1)"
else
  NEED_GH=true
fi

# Check if chezmoi is already installed
if command -v chezmoi >/dev/null 2>&1; then
  ok "chezmoi is already installed: $(chezmoi --version | head -n1)"
else
  NEED_CHEZMOI=true
fi

# Check if lazygit is already installed
if command -v lazygit >/dev/null 2>&1; then
  ok "lazygit is already installed: $(lazygit --version | head -n1)"
else
  NEED_LAZYGIT=true
fi

# Check if cargo is already installed
if command -v cargo >/dev/null 2>&1; then
  ok "cargo is already installed: $(cargo --version | head -n1)"
  info "Checking for Rust updates…"
  if command -v rustup >/dev/null 2>&1; then
    rustup update
    ok "Rust toolchain updated"
  fi
else
  NEED_CARGO=true
fi

# Check if bob-nvim is already installed
if command -v bob >/dev/null 2>&1; then
  ok "bob-nvim is already installed: $(bob --version | head -n1)"
else
  NEED_BOB=true
fi

# Check if fzf is already installed
if command -v fzf >/dev/null 2>&1; then
  ok "fzf is already installed: $(fzf --version | head -n1)"
else
  NEED_FZF=true
fi

# Check if yazi is already installed
if command -v yazi >/dev/null 2>&1; then
  ok "yazi is already installed: $(yazi --version | head -n1)"
else
  NEED_YAZI=true
fi

# Check if ripgrep is already installed
if command -v rg >/dev/null 2>&1; then
  ok "ripgrep is already installed: $(rg --version | head -n1)"
else
  NEED_RIPGREP=true
fi

# Check if fd is already installed
if command -v fd >/dev/null 2>&1; then
  ok "fd is already installed: $(fd --version | head -n1)"
else
  NEED_FD=true
fi

# Check if git is already installed
if command -v git >/dev/null 2>&1; then
  ok "git is already installed: $(git --version | head -n1)"
else
  NEED_GIT=true
fi

# Check if 1Password CLI is already installed
if command -v op >/dev/null 2>&1; then
  ok "1Password CLI is already installed: $(op --version)"
else
  NEED_1PASSWORD=true
fi

# Exit if everything is already installed
if [[ "$NEED_GH" == false && "$NEED_CHEZMOI" == false && "$NEED_LAZYGIT" == false && "$NEED_CARGO" == false && "$NEED_BOB" == false && "$NEED_FZF" == false && "$NEED_YAZI" == false && "$NEED_RIPGREP" == false && "$NEED_FD" == false && "$NEED_GIT" == false && "$NEED_1PASSWORD" == false ]]; then
  ok "All tools are already installed!"
  exit 0
fi

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

# 4. Install GitHub CLI if needed
if [[ "$NEED_GH" == true ]]; then
  info "Installing GitHub CLI (gh)…"
  
  sudo mkdir -p -m 755 /etc/apt/keyrings
  tmpkey="$(mktemp)"
  wget -nv -O "$tmpkey" https://cli.github.com/packages/githubcli-archive-keyring.gpg
  sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null <"$tmpkey"
  rm -f "$tmpkey"
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

  sudo mkdir -p -m 755 /etc/apt/sources.list.d
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null

  info "Updating apt cache…"
  sudo apt update

  sudo apt install -y gh

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI installed successfully: $(gh --version | head -n1)"
  else
    error "GitHub CLI installation appears to have failed."
    exit 1
  fi
fi

# 5. Install chezmoi if needed
if [[ "$NEED_CHEZMOI" == true ]]; then
  info "Installing chezmoi…"
  
  # Install chezmoi using the official install script
  sh -c "$(wget -qO- https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
  
  # Add ~/.local/bin to PATH if not already there
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
  fi
  
  if command -v chezmoi >/dev/null 2>&1; then
    ok "chezmoi installed successfully: $(chezmoi --version | head -n1)"
  else
    error "chezmoi installation appears to have failed."
    exit 1
  fi
fi

# 6. Install lazygit if needed
if [[ "$NEED_LAZYGIT" == true ]]; then
  info "Installing lazygit…"
  
  # Get the latest lazygit version and install it
  LAZYGIT_VERSION=$(wget -qO- "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  wget -qO lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit /usr/local/bin
  rm -f lazygit lazygit.tar.gz
  
  if command -v lazygit >/dev/null 2>&1; then
    ok "lazygit installed successfully: $(lazygit --version | head -n1)"
  else
    error "lazygit installation appears to have failed."
    exit 1
  fi
fi

# 7. Install cargo (Rust toolchain) if needed
if [[ "$NEED_CARGO" == true ]]; then
  info "Installing Rust toolchain (cargo)…"
  
  # Install build dependencies needed for Rust
  info "Installing build dependencies…"
  sudo apt update
  sudo apt install -y build-essential curl
  
  # Install Rust using rustup
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  
  # Source cargo environment
  source "$HOME/.cargo/env"
  
  if command -v cargo >/dev/null 2>&1; then
    ok "cargo installed successfully: $(cargo --version | head -n1)"
  else
    error "cargo installation appears to have failed."
    exit 1
  fi
fi

# 8. Install bob-nvim using cargo if needed
if [[ "$NEED_BOB" == true ]]; then
  info "Installing bob-nvim…"
  
  # Ensure cargo is available (either just installed or was already present)
  if ! command -v cargo >/dev/null 2>&1; then
    # Try to source cargo env in case it was just installed
    if [[ -f "$HOME/.cargo/env" ]]; then
      source "$HOME/.cargo/env"
    fi
    
    if ! command -v cargo >/dev/null 2>&1; then
      error "cargo is required to install bob-nvim but is not available."
      exit 1
    fi
  fi
  
  # Install bob-nvim using cargo
  cargo install --git https://github.com/MordechaiHadad/bob.git
  
  # Add cargo bin to PATH if not already there
  if [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
  fi
  
  if command -v bob >/dev/null 2>&1; then
    ok "bob-nvim installed successfully: $(bob --version | head -n1)"
    
    # Install and use stable Neovim version
    info "Installing stable Neovim via bob…"
    bob install stable
    bob use stable
    ok "Neovim stable version installed and activated"
  else
    error "bob-nvim installation appears to have failed."
    exit 1
  fi
fi

# 9. Install fzf if needed
if [[ "$NEED_FZF" == true ]]; then
  info "Installing fzf…"
  
  # Clone fzf repository
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  
  # Install fzf
  "$HOME/.fzf/install" --all
  
  if command -v fzf >/dev/null 2>&1; then
    ok "fzf installed successfully: $(fzf --version | head -n1)"
  else
    error "fzf installation appears to have failed."
    exit 1
  fi
fi

# 10. Install yazi if needed
if [[ "$NEED_YAZI" == true ]]; then
  info "Installing yazi…"
  
  # Ensure cargo is available (either just installed or was already present)
  if ! command -v cargo >/dev/null 2>&1; then
    # Try to source cargo env in case it was just installed
    if [[ -f "$HOME/.cargo/env" ]]; then
      source "$HOME/.cargo/env"
    fi
    
    if ! command -v cargo >/dev/null 2>&1; then
      error "cargo is required to install yazi but is not available."
      exit 1
    fi
  fi
  
  # Install yazi using cargo
  cargo install --force yazi-build
  cargo install --locked yazi-fm yazi-cli
  
  # Add cargo bin to PATH if not already there
  if [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
  fi
  
  if command -v yazi >/dev/null 2>&1; then
    ok "yazi installed successfully: $(yazi --version | head -n1)"
  else
    error "yazi installation appears to have failed."
    exit 1
  fi
fi

# 11. Install git if needed
if [[ "$NEED_GIT" == true ]]; then
  info "Installing git…"
  
  sudo apt update
  sudo apt install -y git
  
  if command -v git >/dev/null 2>&1; then
    ok "git installed successfully: $(git --version | head -n1)"
  else
    error "git installation appears to have failed."
    exit 1
  fi
fi

# 12. Install ripgrep if needed
if [[ "$NEED_RIPGREP" == true ]]; then
  info "Installing ripgrep…"
  
  sudo apt update
  sudo apt install -y ripgrep
  
  if command -v rg >/dev/null 2>&1; then
    ok "ripgrep installed successfully: $(rg --version | head -n1)"
  else
    error "ripgrep installation appears to have failed."
    exit 1
  fi
fi

# 13. Install fd if needed
if [[ "$NEED_FD" == true ]]; then
  info "Installing fd…"
  
  sudo apt update
  sudo apt install -y fd-find
  
  # Create symlink from fdfind to fd (Ubuntu packages it as fd-find)
  if command -v fdfind >/dev/null 2>&1; then
    sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
  fi
  
  if command -v fd >/dev/null 2>&1; then
    ok "fd installed successfully: $(fd --version | head -n1)"
  else
    error "fd installation appears to have failed."
    exit 1
  fi
fi

# 14. Install 1Password CLI if needed
if [[ "$NEED_1PASSWORD" == true ]]; then
  info "Installing 1Password CLI…"
  
  # Add 1Password's signing key
  sudo mkdir -p -m 755 /etc/apt/keyrings
  tmpkey="$(mktemp)"
  wget -nv -O "$tmpkey" https://downloads.1password.com/linux/keys/1password.asc
  sudo tee /etc/apt/keyrings/1password-archive-keyring.asc >/dev/null <"$tmpkey"
  rm -f "$tmpkey"
  sudo chmod go+r /etc/apt/keyrings/1password-archive-keyring.asc
  
  # Add 1Password's repository
  sudo mkdir -p -m 755 /etc/apt/sources.list.d
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/1password-archive-keyring.asc] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
    | sudo tee /etc/apt/sources.list.d/1password.list >/dev/null
  
  # Add debsig-verify policy
  sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
  wget -nv -O - https://downloads.1password.com/linux/debian/debsig/1password.pol \
    | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null
  sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
  wget -nv -O - https://downloads.1password.com/linux/keys/1password.asc \
    | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
  
  # Update apt and install 1Password CLI
  info "Updating apt cache…"
  sudo apt update
  sudo apt install -y 1password-cli
  
  if command -v op >/dev/null 2>&1; then
    ok "1Password CLI installed successfully: $(op --version)"
  else
    error "1Password CLI installation appears to have failed."
    exit 1
  fi
fi

ok "All required tools are now installed!"
