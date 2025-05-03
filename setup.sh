#!/bin/bash

# Claude Code Setup Script for Ubuntu
# This script installs NVM, the latest Node.js, Python, and Claude Code

set -e  # Exit immediately if a command fails

# Print colored status messages
function print_status() {
    echo -e "\n\033[1;34m==>\033[0m \033[1m$1\033[0m"
}

print_status "Updating package lists"
sudo apt update

print_status "Installing dependencies"
sudo apt install -y curl wget build-essential libssl-dev

print_status "Installing NVM (Node Version Manager)"
# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Source NVM for current session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Verify NVM installation
nvm --version
if [ $? -ne 0 ]; then
    print_status "NVM installation failed. Please check the error messages above."
    exit 1
fi

print_status "Installing latest stable Node.js version using NVM"
nvm install --lts
nvm use --lts

# Set the installed version as default
nvm alias default node

# Verify installations
node_version=$(node -v)
npm_version=$(npm -v)
print_status "Installed Node.js $node_version and npm $npm_version"

print_status "Installing latest Python"
sudo apt install -y python3 python3-pip

# Verify Python installation
python_version=$(python3 --version)
print_status "Installed $python_version"

print_status "Installing Claude Code globally"
npm install -g @anthropic/claude-code

print_status "Creating configuration directory"
mkdir -p "$HOME/.config/anthropic"

print_status "Installation complete!"
echo "To use Claude Code:"
echo "1. Make sure you have an Anthropic API key"
echo "2. Run 'claude-code' to start using the CLI"
echo "3. On first run, you'll be prompted to enter your API key"
echo ""
echo "For new terminal sessions, you may need to run:"
echo "  export NVM_DIR=\"\$HOME/.nvm\""
echo "  [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"  # This loads nvm"
echo ""
echo "If you encountered any issues, please visit https://support.anthropic.com"
echo "For API documentation, see https://docs.anthropic.com/en/docs/"
