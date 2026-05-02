#!/bin/bash

# LibTMail Quick Install Script
# One-click installation of LibTMail mail server
# Author: tda_45
# Version: 1.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
REPO_URL="https://github.com/tda45/LibTMail.git"
INSTALL_DIR="/tmp/LibTMail"
TEMP_DIR="/tmp/libtmail_install"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to show banner
show_banner() {
    clear
    echo -e "${BLUE}"
    echo "  _                 _            _     _   "
    echo " | |               | |          | |   | |  "
    echo " | |     ___   __ _| |_ __ _ ___| |_  | |  "
    echo " | |    / _ \ / _\` | __/ _\` / __| __| | |  "
    echo " | |___| (_) | (_| | || (_| \__ \ |_  | |  "
    echo " |______\___/ \__, |\__\__,_|___/\__| |_|  "
    echo "              __/ |                      "
    echo "             |___/     Mail Server        "
    echo -e "${NC}"
    echo -e "${GREEN}LibTMail - Linux Mail Server Configuration${NC}"
    echo -e "${YELLOW}Quick Install Script v1.0${NC}"
    echo
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        print_status "Try: sudo ./install.sh"
        exit 1
    fi
}

# Function to check internet connection
check_internet() {
    print_status "Checking internet connection..."
    if ! ping -c 1 google.com &> /dev/null; then
        print_error "No internet connection detected"
        print_status "Please check your network connection and try again"
        exit 1
    fi
    print_status "Internet connection OK"
}

# Function to check system requirements
check_requirements() {
    print_header "Checking System Requirements"
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot detect operating system"
        exit 1
    fi
    
    . /etc/os-release
    print_status "OS: $PRETTY_NAME"
    
    # Check architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" ]]; then
        print_warning "Architecture: $ARCH (x86_64 recommended)"
    else
        print_status "Architecture: $ARCH ✓"
    fi
    
    # Check RAM
    RAM=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    if [[ $RAM -lt 2 ]]; then
        print_warning "RAM: ${RAM}GB (2GB+ recommended)"
    else
        print_status "RAM: ${RAM}GB ✓"
    fi
    
    # Check disk space
    DISK=$(df / | awk 'NR==2 {print $4}')
    DISK_GB=$((DISK / 1024 / 1024))
    if [[ $DISK_GB -lt 20 ]]; then
        print_warning "Disk Space: ${DISK_GB}GB (20GB+ recommended)"
    else
        print_status "Disk Space: ${DISK_GB}GB ✓"
    fi
    
    # Check required commands
    local required_commands=("git" "curl" "wget")
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            print_status "$cmd: ✓"
        else
            print_warning "$cmd: ✗ (will be installed)"
        fi
    done
}

# Function to install dependencies
install_dependencies() {
    print_header "Installing Dependencies"
    
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu
        apt update
        apt install -y git curl wget unzip
    elif [[ -f /etc/redhat-release ]]; then
        # CentOS/RHEL/Fedora
        if command -v dnf &> /dev/null; then
            dnf install -y git curl wget unzip
        else
            yum install -y git curl wget unzip
        fi
    else
        print_error "Unsupported distribution"
        exit 1
    fi
    
    print_status "Dependencies installed"
}

# Function to download LibTMail
download_libtmail() {
    print_header "Downloading LibTMail"
    
    # Clean up previous downloads
    rm -rf "$INSTALL_DIR" "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # Download from GitHub
    if command -v git &> /dev/null; then
        print_status "Cloning from GitHub..."
        git clone "$REPO_URL" "$INSTALL_DIR"
    else
        print_status "Downloading as ZIP file..."
        wget -O "$TEMP_DIR/LibTMail.zip" "https://github.com/tda45/LibTMail/archive/refs/heads/master.zip"
        unzip "$TEMP_DIR/LibTMail.zip" -d "$TEMP_DIR"
        mv "$TEMP_DIR/LibTMail-master" "$INSTALL_DIR"
    fi
    
    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_error "Failed to download LibTMail"
        exit 1
    fi
    
    print_status "LibTMail downloaded successfully"
}

# Function to verify installation
verify_installation() {
    print_header "Verifying Installation"
    
    local required_files=("config.sh" "uninstall.sh" "README.md" "LICENSE")
    
    for file in "${required_files[@]}"; do
        if [[ -f "$INSTALL_DIR/$file" ]]; then
            print_status "$file: ✓"
        else
            print_error "$file: ✗ (missing)"
            exit 1
        fi
    done
    
    # Check if config.sh is executable
    chmod +x "$INSTALL_DIR/config.sh"
    chmod +x "$INSTALL_DIR/uninstall.sh"
    
    print_status "Installation verified"
}

# Function to show installation options
show_options() {
    print_header "Installation Options"
    
    echo "Choose installation type:"
    echo "1) Standard Installation (Interactive)"
    echo "2) Quick Installation (Default settings)"
    echo "3) Custom Installation (Advanced)"
    echo "4) Exit"
    echo
    
    while true; do
        read -p "Enter your choice [1-4]: " choice
        case $choice in
            1)
                INSTALL_TYPE="standard"
                break
                ;;
            2)
                INSTALL_TYPE="quick"
                break
                ;;
            3)
                INSTALL_TYPE="custom"
                break
                ;;
            4)
                print_status "Installation cancelled"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please enter 1-4."
                ;;
        esac
    done
}

# Function to run standard installation
run_standard_install() {
    print_header "Starting Standard Installation"
    
    cd "$INSTALL_DIR"
    ./config.sh
}

# Function to run quick installation
run_quick_install() {
    print_header "Starting Quick Installation"
    
    cd "$INSTALL_DIR"
    
    # Create answers file for non-interactive installation
    cat > answers.txt << EOF
example.com
mail
admin@example.com
EOF
    
    # Run with automated answers
    ./config.sh < answers.txt
    
    # Clean up
    rm -f answers.txt
}

# Function to run custom installation
run_custom_install() {
    print_header "Custom Installation Options"
    
    echo "Custom installation allows you to:"
    echo "1) Skip certain components"
    echo "2) Use custom paths"
    echo "3) Modify configuration before installation"
    echo
    
    read -p "Do you want to modify configuration? (y/N): " modify_config
    
    if [[ $modify_config =~ ^[Yy]$ ]]; then
        print_status "Opening configuration for editing..."
        sleep 2
        
        # Open config.sh in default editor
        if command -v nano &> /dev/null; then
            nano "$INSTALL_DIR/config.sh"
        elif command -v vi &> /dev/null; then
            vi "$INSTALL_DIR/config.sh"
        else
            print_warning "No editor found. You can manually edit: $INSTALL_DIR/config.sh"
            read -p "Press Enter to continue..."
        fi
    fi
    
    cd "$INSTALL_DIR"
    ./config.sh
}

# Function to show post-installation summary
show_summary() {
    print_header "Installation Summary"
    
    echo -e "${GREEN}LibTMail has been successfully installed!${NC}"
    echo
    echo "Installation Directory: $INSTALL_DIR"
    echo "Configuration Script: $INSTALL_DIR/config.sh"
    echo "Uninstall Script: $INSTALL_DIR/uninstall.sh"
    echo
    echo "Next Steps:"
    echo "1. Configure your DNS MX records"
    echo "2. Test email functionality"
    echo "3. Set up email clients"
    echo
    echo "Management Commands:"
    echo "  mailadmin     - Manage email users"
    echo "  mailbackup    - Backup mail server"
    echo "  mailmonitor   - Monitor services"
    echo "  mailqueue     - Manage mail queue"
    echo
    echo "For detailed documentation, see: $INSTALL_DIR/README.md"
    echo
    print_warning "Save your passwords and configuration securely!"
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}

# Function to handle errors
handle_error() {
    print_error "Installation failed!"
    print_status "Check the logs above for error details"
    print_status "You can try running the installation manually:"
    echo "  cd $INSTALL_DIR"
    echo "  sudo ./config.sh"
    cleanup
    exit 1
}

# Main function
main() {
    show_banner
    
    # Set error handling
    trap handle_error ERR
    
    check_root
    check_internet
    check_requirements
    install_dependencies
    download_libtmail
    verify_installation
    show_options
    
    case $INSTALL_TYPE in
        "standard")
            run_standard_install
            ;;
        "quick")
            run_quick_install
            ;;
        "custom")
            run_custom_install
            ;;
    esac
    
    show_summary
    cleanup
    
    print_status "Quick install completed successfully!"
}

# Run main function
main "$@"
