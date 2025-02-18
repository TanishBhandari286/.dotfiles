#!/bin/bash

REPO="https://github.com/TanishBhandari286/.dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
LOG_FILE="$HOME/mac-setup.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

log "Starting macOS setup..."

# Clone the dotfiles repository
if [ ! -d "$DOTFILES_DIR" ]; then
    log "Cloning dotfiles repository..."
    if ! git clone --depth=1 "$REPO" "$DOTFILES_DIR"; then
        log "Error: Failed to clone repository."
        exit 1
    fi
else
    log "Dotfiles repository already exists. Pulling latest changes..."
    cd "$DOTFILES_DIR" || exit
    if ! git pull; then
        log "Error: Failed to update repository."
        exit 1
    fi
fi

# Install Homebrew if missing
if ! command -v brew &>/dev/null; then
    log "Homebrew not found. Installing..."
    if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        log "Error: Homebrew installation failed."
        exit 1
    fi
else
    log "Homebrew is already installed."
fi

# Install GNU Stow
if ! command -v stow &>/dev/null; then
    log "Installing Stow..."
    if ! brew install stow; then
        log "Error: Failed to install Stow."
        exit 1
    fi
else
    log "Stow is already installed."
fi

# Stowing dotfiles
cd "$DOTFILES_DIR" || exit
mkdir -p "$HOME/.config"

# Function to check for conflicts
check_conflict() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        log "Warning: $target already exists. Skipping..."
        return 1
    fi
    return 0
}

# Stow standalone dotfiles
for file in zshrc .tmux.conf Brewfile; do
    check_conflict "$HOME/$file" && stow -t "$HOME" "$file"
done

# Stow config directories
for dir in flavors htop kitty lazygit neofetch nvim portal raycast starship thefuck yazi; do
    check_conflict "$HOME/.config/$dir" && stow -t "$HOME/.config" "$dir"
done

log "Dotfiles installation completed!"

# Install applications and CLI tools from Brewfile
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
    log "Installing applications from Brewfile..."
    if ! brew bundle --file="$DOTFILES_DIR/Brewfile"; then
        log "Error: Failed to install packages from Brewfile."
        exit 1
    fi
else
    log "No Brewfile found. Skipping Homebrew app installation."
fi

log "macOS setup completed successfully!"

