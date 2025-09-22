#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd $SCRIPT_DIR && git rev-parse --show-toplevel 2>/dev/null)
source $REPO_DIR/setup_utils/utils.sh

echo "Setting up GitHub CLI (gh)..."

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  if ! command -v gh &> /dev/null; then
    echo "Installing gh via Homebrew..."
    brew install gh
  else
    echo "✅ gh is already installed"
  fi

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux (Ubuntu/Debian)
  if ! command -v gh &> /dev/null; then
    echo "Installing gh via apt..."
    
    # Install curl if not present
    type -p curl >/dev/null || sudo apt install curl -y
    
    # Add GitHub CLI repository
    echo "Adding GitHub CLI repository..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y
    
    if [ $? -eq 0 ]; then
      echo "✅ GitHub CLI (gh) installed successfully"
    else
      echo "❌ GitHub CLI installation failed"
      exit 1
    fi
  else
    echo "✅ gh is already installed"
  fi

else
  echo "Unsupported OS. This script supports macOS and Ubuntu only."
  exit 1
fi

# Check if gh is now available
if command -v gh &> /dev/null; then
  echo "✅ GitHub CLI (gh) setup completed"
  
  # Prompt for login
  echo ""
  echo "Would you like to login to GitHub now? (y/n)"
  read -r answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Starting GitHub CLI authentication..."
    gh auth login
  else
    echo "You can login later using: gh auth login"
  fi
else
  echo "❌ GitHub CLI installation failed"
  exit 1
fi