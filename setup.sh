#!/usr/bin/env bash

set -euo pipefail

echo "========================================="
echo " Fedora Neovim Development Environment"
echo "========================================="

# Detect package manager
if command -v dnf5 >/dev/null 2>&1; then
    DNF="dnf5"
else
    DNF="dnf"
fi

echo "Using package manager: $DNF"

echo
echo "[1/5] Updating system..."
sudo "$DNF" upgrade -y

echo
echo "[2/5] Installing packages..."

PACKAGES=(
    neovim
    git
    gcc
    gcc-c++
    make
    cmake
    nodejs
    npm
    python3
    python3-pip
    clang
    ripgrep
    wl-clipboard
)

for pkg in "${PACKAGES[@]}"; do
    if ! rpm -q "$pkg" >/dev/null 2>&1; then
        echo "Installing $pkg..."
        sudo "$DNF" install -y "$pkg"
    else
        echo "$pkg already installed"
    fi
done


echo
echo "[3/5] Installing Tree-sitter CLI..."

if command -v npm >/dev/null 2>&1; then
    if ! command -v tree-sitter >/dev/null 2>&1; then
        sudo npm install -g tree-sitter-cli
    else
        echo "Tree-sitter already installed"
    fi
else
    echo "npm unavailable, skipping Tree-sitter CLI"
fi


echo
echo "[4/5] Creating Neovim directories..."

mkdir -p "$HOME/.config/nvim"


echo
echo "[5/5] Checking installation..."

declare -A CHECKS=(
    ["Neovim"]="nvim --version | head -n1"
    ["Git"]="git --version"
    ["Node"]="node --version"
    ["Python"]="python3 --version"
    ["Clang"]="clang --version | head -n1"
    ["Ripgrep"]="rg --version | head -n1"
)

for name in "${!CHECKS[@]}"; do
    echo -n "$name: "
    bash -c "${CHECKS[$name]}" || echo "not found"
done


echo
echo "========================================="
echo " Done!"
echo "========================================="
echo
echo "Put your Neovim config here:"
echo "  ~/.config/nvim/init.lua"
echo
echo "Start Neovim:"
echo "  nvim"
echo
echo "Plugins and LSP servers will install automatically."