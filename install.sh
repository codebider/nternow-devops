#!/bin/bash

# Nternow DevOps Tool Installer
# This script installs the Nternow DevOps Connection Tool
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/devops/main/install.sh | bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where this script is located (if running locally)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}Script directory: ${SCRIPT_DIR}${NC}"

# Check if we're running locally or via curl
if [ -f "$SCRIPT_DIR/connect.sh" ]; then
    # Running locally - use local files
    USE_LOCAL=true
    INSTALL_DIR="$SCRIPT_DIR"
else
    # Running via curl - download from GitHub
    USE_LOCAL=false
    INSTALL_DIR="$HOME/.nternow-devops"
    # Update this URL with your actual GitHub repository
    REPO_URL="https://raw.githubusercontent.com/YOUR_ORG/YOUR_REPO/main/devops"
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Nternow DevOps Tool Installation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Detect shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
    SHELL_NAME="bash"
    if [ -f "$HOME/.bash_profile" ] && [ ! -f "$HOME/.bashrc" ]; then
        SHELL_RC="$HOME/.bash_profile"
    fi
else
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="zsh"
fi

echo -e "${GREEN}Detected shell: ${SHELL_NAME}${NC}"
echo -e "${GREEN}Config file: ${SHELL_RC}${NC}"
if [ "$USE_LOCAL" = true ]; then
    echo -e "${BLUE}Installation mode: Local${NC}"
else
    echo -e "${BLUE}Installation mode: Remote (via curl)${NC}"
fi
echo ""

if [ "$USE_LOCAL" = false ]; then
    # Create installation directory for remote installation
    mkdir -p "$INSTALL_DIR"
    echo -e "${GREEN}✓ Created installation directory: ${INSTALL_DIR}${NC}"
    
    # Download files
    echo -e "${BLUE}Downloading files...${NC}"
    
    # Function to download file
    download_file() {
        local file=$1
        local url="${REPO_URL}/${file}"
        echo "  Downloading ${file}..."
        
        if command -v curl &> /dev/null; then
            curl -fsSL "$url" -o "$INSTALL_DIR/$file" || {
                echo -e "${RED}✗ Failed to download ${file}${NC}"
                echo -e "${YELLOW}Please update REPO_URL in the installer or install manually.${NC}"
                exit 1
            }
        elif command -v wget &> /dev/null; then
            wget -q "$url" -O "$INSTALL_DIR/$file" || {
                echo -e "${RED}✗ Failed to download ${file}${NC}"
                echo -e "${YELLOW}Please update REPO_URL in the installer or install manually.${NC}"
                exit 1
            }
        else
            echo -e "${RED}✗ Neither curl nor wget is available${NC}"
            exit 1
        fi
    }
    
    # Download required files
    download_file "connect.sh"
    download_file "connect.py" 2>/dev/null || true
else
    echo -e "${GREEN}✓ Using local files from: ${INSTALL_DIR}${NC}"
fi

# Make scripts executable
chmod +x "$INSTALL_DIR/connect.sh"
chmod +x "$INSTALL_DIR/connect.py" 2>/dev/null || true
echo -e "${GREEN}✓ Made scripts executable${NC}"

# Check if already installed in shell config
if grep -q "Nternow DevOps Tools" "$SHELL_RC" 2>/dev/null; then
    echo -e "${YELLOW}It looks like the tool is already installed.${NC}"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Installation cancelled.${NC}"
        exit 0
    fi
    # Remove old installation
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i.bak '/# Nternow DevOps Tools/,/alias nternow-connect/d' "$SHELL_RC"
    else
        sed -i '/# Nternow DevOps Tools/,/alias nternow-connect/d' "$SHELL_RC"
    fi
    echo -e "${GREEN}✓ Removed old installation${NC}"
fi

# Add to PATH
echo "" >> "$SHELL_RC"
echo "# Nternow DevOps Tools" >> "$SHELL_RC"
if [ "$USE_LOCAL" = true ]; then
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_RC"
else
    echo "export PATH=\"\$HOME/.nternow-devops:\$PATH\"" >> "$SHELL_RC"
fi
echo "alias nternow-connect=\"connect.sh\"" >> "$SHELL_RC"

echo -e "${GREEN}✓ Added to ${SHELL_RC}${NC}"

# Automatically source the config file (like nvm does)
echo -e "${BLUE}Loading configuration in current shell...${NC}"
if [ -f "$SHELL_RC" ]; then
    # Source the config file to make it available in current session
    # This is similar to how nvm does it
    if [ -n "$ZSH_VERSION" ]; then
        # For zsh, source the file
        source "$SHELL_RC" 2>/dev/null || true
    elif [ -n "$BASH_VERSION" ]; then
        # For bash, source the file
        source "$SHELL_RC" 2>/dev/null || true
    fi
    echo -e "${GREEN}✓ Configuration loaded${NC}"
fi

# Check prerequisites
echo ""
echo -e "${BLUE}Checking prerequisites...${NC}"

MISSING_PREREQS=0

if ! command -v aws &> /dev/null; then
    echo -e "${RED}✗ AWS CLI is not installed${NC}"
    echo "  Install: brew install awscli"
    MISSING_PREREQS=1
else
    echo -e "${GREEN}✓ AWS CLI is installed${NC}"
fi

if ! command -v session-manager-plugin &> /dev/null; then
    echo -e "${RED}✗ Session Manager Plugin is not installed${NC}"
    echo "  Install: brew install --cask session-manager-plugin"
    MISSING_PREREQS=1
else
    echo -e "${GREEN}✓ Session Manager Plugin is installed${NC}"
fi

if ! command -v expect &> /dev/null; then
    echo -e "${YELLOW}⚠ expect is not installed (optional)${NC}"
    echo "  For auto-switching to ubuntu user: brew install expect"
else
    echo -e "${GREEN}✓ expect is installed${NC}"
fi

echo ""
if [ $MISSING_PREREQS -eq 1 ]; then
    echo -e "${YELLOW}Some prerequisites are missing. Please install them before using the tool.${NC}"
else
    echo -e "${GREEN}All prerequisites are installed!${NC}"
fi

# Installation complete
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}✓ Configuration automatically loaded in current session${NC}"
echo -e "${YELLOW}Note: New terminal windows will automatically load the configuration${NC}"
echo ""
echo -e "${GREEN}Usage:${NC}"
echo "  connect.sh staging-ec2"
echo "  connect.sh staging-db"
echo "  connect.sh prod-ec2"
echo "  connect.sh prod-db"
echo ""
echo "  Or use the alias:"
echo "  nternow-connect staging-ec2"
echo ""
echo -e "${BLUE}Files installed to: ${INSTALL_DIR}${NC}"
echo ""
