#!/usr/bin/env bash
set -euo pipefail

############################################
# Config – tweak only if you need a pin
############################################
NVM_VERSION_LATEST="v0.40.3"     # last checked 2025‑04‑23
PYENV_ROOT="${HOME}/.pyenv"      # pyenv install location
GH_APT_SOURCE="/etc/apt/sources.list.d/github-cli.list"

############################################
# Helpers
############################################
log() { printf '\n\033[1;34m▶ %s\033[0m\n' "$*"; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

############################################
# 1. nvm + latest Node.js (LTS)
############################################
install_nvm() {
  if need_cmd nvm; then
    log "nvm already installed – skipping"
    return
  fi

  log "Installing nvm ${NVM_VERSION_LATEST}"
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION_LATEST}/install.sh" | bash
  # shellcheck source=/dev/null
  export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh"
}

install_latest_node() {
  # load nvm in non‑login shells
  export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  local want="lts/*"            # change to "node" for bleeding‑edge stable
  if nvm ls "$want" | grep -q "->"; then
    log "Node ${want} already present – skipping"
  else
    log "Installing Node (${want})"
    nvm install --lts --latest-npm
    nvm alias default "$want"
  fi
}

############################################
# 2. Claude Code (global npm package)
############################################
install_claude_code() {
  if need_cmd claude; then
    log "Claude Code already installed – skipping"
  else
    log "Installing Claude Code CLI"
    npm install -g @anthropic-ai/claude-code
  fi
}

############################################
# 3. pyenv + newest CPython
############################################
install_pyenv() {
  if [ -d "$PYENV_ROOT" ]; then
    log "pyenv already cloned – pulling latest"
    git -C "$PYENV_ROOT" pull
  else
    log "Cloning pyenv"
    git clone https://github.com/pyenv/pyenv.git "$PYENV_ROOT"
  fi

  # shellcheck disable=SC1091
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
}

install_latest_python() {
  # Get newest stable 3.x release string (excludes dev / rc tracks)
  local latest
  latest=$(pyenv install --list \
            | grep -E '^\s*3\.[0-9]+\.[0-9]+$' \
            | tail -1 | tr -d ' ')
  if pyenv versions --bare | grep -q "^${latest}\$"; then
    log "Python ${latest} already installed – skipping"
  else
    log "Installing Python ${latest}"
    # Ensure build deps (harmless to reinstall)
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends \
         build-essential libssl-dev zlib1g-dev \
         libbz2-dev libreadline-dev libsqlite3-dev \
         libncursesw5-dev xz-utils tk-dev libxml2-dev \
         libxmlsec1-dev libffi-dev liblzma-dev
    pyenv install "${latest}"
  fi
  pyenv global "${latest}"
}

############################################
# 4. GitHub CLI (gh)
############################################
install_gh_cli() {
  if need_cmd gh; then
    log "gh already installed – skipping"
    return
  fi
  log "Installing GitHub CLI"
  if [ ! -f "${GH_APT_SOURCE}" ]; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
      https://cli.github.com/packages stable main" \
      | sudo tee "${GH_APT_SOURCE}" > /dev/null
  fi
  sudo apt-get update -qq
  sudo apt-get install -y gh
}

############################################
# Kick‑off
############################################
main() {
  log "🔧 Starting idempotent toolchain bootstrap…"

  install_nvm
  install_latest_node
  install_claude_code
  install_pyenv
  install_latest_python
  install_gh_cli

  log "✅  Done!  Open a new shell or run 'exec \$SHELL' to refresh your environment."
}

main "$@"
