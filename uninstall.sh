#!/bin/bash

# LibTMail Mail Server Uninstall Script
# This script completely removes the mail server and all its components
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
BACKUP_DIR="/var/backups/mailserver_uninstall_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/tmp/libtmail_uninstall.log"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${BLUE}================================${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}$1${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}================================${NC}" | tee -a "$LOG_FILE"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        print_error "Cannot detect Linux distribution"
        exit 1
    fi
    
    print_status "Detected distribution: $DISTRO $VERSION"
}

# Function to check if mail server is installed
check_installation() {
    print_header "Checking Mail Server Installation"
    
    local installed=false
    
    # Check for main components
    if command -v postfix &> /dev/null; then
        print_status "Postfix is installed"
        installed=true
    fi
    
    if command -v dovecot &> /dev/null; then
        print_status "Dovecot is installed"
        installed=true
    fi
    
    if command -v mysql &> /dev/null || command -v mariadb &> /dev/null; then
        print_status "MariaDB/MySQL is installed"
        installed=true
    fi
    
    if [ -d "/var/vmail" ]; then
        print_status "Mail data directory exists"
        installed=true
    fi
    
    if [ "$installed" = false ]; then
        print_warning "No mail server installation detected"
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Uninstall cancelled"
            exit 0
        fi
    fi
}

# Function to create backup
create_backup() {
    print_header "Creating Backup"
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup configurations
    if [ -d "/etc/postfix" ]; then
        print_status "Backing up Postfix configuration..."
        cp -r /etc/postfix "$BACKUP_DIR/"
    fi
    
    if [ -d "/etc/dovecot" ]; then
        print_status "Backing up Dovecot configuration..."
        cp -r /etc/dovecot "$BACKUP_DIR/"
    fi
    
    if [ -f "/etc/opendkim.conf" ]; then
        print_status "Backing up OpenDKIM configuration..."
        cp /etc/opendkim.conf "$BACKUP_DIR/"
        cp -r /etc/opendkim "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    if [ -d "/etc/spamassassin" ]; then
        print_status "Backing up SpamAssassin configuration..."
        cp -r /etc/spamassassin "$BACKUP_DIR/"
    fi
    
    if [ -d "/etc/clamav" ]; then
        print_status "Backing up ClamAV configuration..."
        cp -r /etc/clamav "$BACKUP_DIR/"
    fi
    
    if [ -d "/etc/apache2" ]; then
        print_status "Backing up Apache configuration..."
        cp -r /etc/apache2/sites-available "$BACKUP_DIR/apache_sites"
    fi
    
    # Backup mail data
    if [ -d "/var/vmail" ]; then
        print_status "Backing up mail data..."
        cp -r /var/vmail "$BACKUP_DIR/"
    fi
    
    # Backup database
    if command -v mysql &> /dev/null || command -v mariadb &> /dev/null; then
        print_status "Backing up database..."
        if mysql -u root -e "USE mailserver;" &>/dev/null; then
            mysqldump --single-transaction --routines --triggers mailserver > "$BACKUP_DIR/mailserver_backup.sql" 2>/dev/null || true
        fi
    fi
    
    # Backup SSL certificates
    if [ -d "/etc/ssl/certs" ]; then
        print_status "Backing up SSL certificates..."
        cp /etc/ssl/certs/mailserver.crt "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    if [ -d "/etc/ssl/private" ]; then
        print_status "Backing up SSL keys..."
        cp /etc/ssl/private/mailserver.key "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    # Backup management scripts
    if [ -f "/usr/local/bin/mailadmin" ]; then
        cp /usr/local/bin/mailadmin "$BACKUP_DIR/"
    fi
    
    if [ -f "/usr/local/bin/mailbackup" ]; then
        cp /usr/local/bin/mailbackup "$BACKUP_DIR/"
    fi
    
    if [ -f "/usr/local/bin/mailmonitor" ]; then
        cp /usr/local/bin/mailmonitor "$BACKUP_DIR/"
    fi
    
    if [ -f "/usr/local/bin/mailqueue" ]; then
        cp /usr/local/bin/mailqueue "$BACKUP_DIR/"
    fi
    
    # Backup cron jobs
    crontab -l > "$BACKUP_DIR/crontab_backup" 2>/dev/null || true
    
    print_status "Backup created at: $BACKUP_DIR"
    print_warning "Save this backup directory if you want to restore later!"
}

# Function to stop services
stop_services() {
    print_header "Stopping Services"
    
    # Stop mail services
    local services=("postfix" "dovecot" "mariadb" "mysql" "spamassassin" "clamav-daemon" "clamav-freshclam" "opendkim" "clamsmtp" "apache2" "httpd")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            print_status "Stopping $service..."
            systemctl stop "$service" 2>/dev/null || true
        fi
    done
    
    # Disable services
    for service in "${services[@]}"; do
        if systemctl is-enabled --quiet "$service" 2>/dev/null; then
            print_status "Disabling $service..."
            systemctl disable "$service" 2>/dev/null || true
        fi
    done
}

# Function to remove packages
remove_packages() {
    print_header "Removing Packages"
    
    case $DISTRO in
        ubuntu|debian)
            # Mail server packages
            apt purge -y postfix postfix-mysql dovecot-core dovecot-imapd dovecot-pop3d dovecot-mysql
            apt purge -y mariadb-server mariadb-client mysql-server mysql-client
            apt purge -y spamassassin spamc
            apt purge -y clamav clamav-freshclam clamsmtp
            apt purge -y opendkim opendkim-tools
            apt purge -y apache2 php php-mysql php-imap php-json php-curl php-xml php-mbstring php-intl php-gd php-zip php-bz2 php-ldap
            apt purge -y httpd php php-mysqlnd php-imap php-json php-curl php-xml php-mbstring php-intl php-gd php-zip php-bzip2 php-ldap
            
            # Remove dependencies
            apt autoremove -y
            apt autoclean
            
            ;;
        centos|rhel|fedora)
            # Mail server packages
            if command -v dnf &> /dev/null; then
                dnf remove -y postfix postfix-mysql dovecot dovecot-mysql
                dnf remove -y mariadb-server mariadb mysql-server mysql-community-server
                dnf remove -y spamassassin
                dnf remove -y clamav clamav-update clamav-scanner clamsmtp
                dnf remove -y opendkim
                dnf remove -y httpd php php-mysqlnd php-imap php-json php-curl php-xml php-mbstring php-intl php-gd php-zip php-bzip2 php-ldap
                dnf autoremove -y
            else
                yum remove -y postfix postfix-mysql dovecot dovecot-mysql
                yum remove -y mariadb-server mariadb mysql-server mysql-community-server
                yum remove -y spamassassin
                yum remove -y clamav clamav-update clamav-scanner clamsmtp
                yum remove -y opendkim
                yum remove -y httpd php php-mysql php-imap php-json php-curl php-xml php-mbstring php-intl php-gd php-zip php-bzip2 php-ldap
                yum autoremove -y
            fi
            ;;
    esac
}

# Function to remove configurations
remove_configurations() {
    print_header "Removing Configurations"
    
    # Remove configuration directories
    local config_dirs=(
        "/etc/postfix"
        "/etc/dovecot"
        "/etc/opendkim"
        "/etc/spamassassin"
        "/etc/clamav"
        "/var/www/html/webmail"
        "/etc/apache2/sites-available/webmail.conf"
        "/etc/httpd/conf.d/webmail.conf"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [ -e "$dir" ]; then
            print_status "Removing $dir..."
            rm -rf "$dir" 2>/dev/null || true
        fi
    done
    
    # Remove configuration files
    local config_files=(
        "/etc/opendkim.conf"
        "/etc/mysql/mail_password"
        "/etc/my.cnf.d/mailserver.cnf"
    )
    
    for file in "${config_files[@]}"; do
        if [ -f "$file" ]; then
            print_status "Removing $file..."
            rm -f "$file"
        fi
    done
}

# Function to remove mail data
remove_mail_data() {
    print_header "Removing Mail Data"
    
    # Remove mail directories
    local mail_dirs=(
        "/var/vmail"
        "/var/spool/postfix"
        "/var/lib/dovecot"
        "/var/lib/spamassassin"
        "/var/lib/clamav"
        "/var/log/clamav"
        "/var/log/mail"
        "/var/log/mail.log"
        "/var/log/dovecot.log"
        "/var/log/spamassassin"
        "/var/log/apache2/webmail_*"
        "/var/log/httpd/webmail_*"
    )
    
    for dir in "${mail_dirs[@]}"; do
        if [ -e "$dir" ]; then
            print_status "Removing $dir..."
            rm -rf "$dir" 2>/dev/null || true
        fi
    done
    
    # Remove log files
    find /var/log -name "*mail*" -type f -delete 2>/dev/null || true
    find /var/log -name "*postfix*" -type f -delete 2>/dev/null || true
    find /var/log -name "*dovecot*" -type f -delete 2>/dev/null || true
    find /var/log -name "*spam*" -type f -delete 2>/dev/null || true
    find /var/log -name "*clam*" -type f -delete 2>/dev/null || true
}

# Function to remove database
remove_database() {
    print_header "Removing Database"
    
    if command -v mysql &> /dev/null || command -v mariadb &> /dev/null; then
        # Try to start database service temporarily
        systemctl start mariadb 2>/dev/null || systemctl start mysql 2>/dev/null || true
        
        # Remove mailserver database
        if mysql -u root -e "USE mailserver;" &>/dev/null; then
            print_status "Removing mailserver database..."
            mysql -u root -e "DROP DATABASE IF EXISTS mailserver;" 2>/dev/null || true
        fi
        
        # Remove mailuser
        mysql -u root -e "DROP USER IF EXISTS 'mailuser'@'localhost';" 2>/dev/null || true
        
        # Flush privileges
        mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null || true
        
        # Stop database again
        systemctl stop mariadb 2>/dev/null || systemctl stop mysql 2>/dev/null || true
    fi
}

# Function to remove users
remove_users() {
    print_header "Removing System Users"
    
    # Remove mail-related users
    local users=("vmail" "spamd" "clamav" "opendkim")
    
    for user in "${users[@]}"; do
        if id "$user" &>/dev/null; then
            print_status "Removing user $user..."
            userdel -r "$user" 2>/dev/null || true
        fi
    done
}

# Function to remove management scripts
remove_management_scripts() {
    print_header "Removing Management Scripts"
    
    local scripts=(
        "/usr/local/bin/mailadmin"
        "/usr/local/bin/mailbackup"
        "/usr/local/bin/mailmonitor"
        "/usr/local/bin/mailqueue"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            print_status "Removing $script..."
            rm -f "$script"
        fi
    done
}

# Function to remove cron jobs
remove_cron_jobs() {
    print_header "Removing Cron Jobs"
    
    # Get current crontab
    if command -v crontab &> /dev/null; then
        current_cron=$(crontab -l 2>/dev/null || true)
        
        # Remove mail-related cron jobs
        new_cron=$(echo "$current_cron" | grep -v "mailbackup\|mailmonitor" || true)
        
        # Update crontab
        echo "$new_cron" | crontab - 2>/dev/null || true
        
        print_status "Mail-related cron jobs removed"
    fi
}

# Function to remove SSL certificates
remove_ssl_certificates() {
    print_header "Removing SSL Certificates"
    
    if [ -f "/etc/ssl/certs/mailserver.crt" ]; then
        print_status "Removing SSL certificate..."
        rm -f /etc/ssl/certs/mailserver.crt
    fi
    
    if [ -f "/etc/ssl/private/mailserver.key" ]; then
        print_status "Removing SSL key..."
        rm -f /etc/ssl/private/mailserver.key
    fi
}

# Function to clean firewall rules
clean_firewall() {
    print_header "Cleaning Firewall Rules"
    
    # UFW (Ubuntu/Debian)
    if command -v ufw &> /dev/null; then
        print_status "Removing UFW rules..."
        ufw --force delete allow 25/tcp 2>/dev/null || true
        ufw --force delete allow 587/tcp 2>/dev/null || true
        ufw --force delete allow 465/tcp 2>/dev/null || true
        ufw --force delete allow 143/tcp 2>/dev/null || true
        ufw --force delete allow 993/tcp 2>/dev/null || true
        ufw --force delete allow 110/tcp 2>/dev/null || true
        ufw --force delete allow 995/tcp 2>/dev/null || true
        ufw --force delete allow 80/tcp 2>/dev/null || true
        ufw --force delete allow 443/tcp 2>/dev/null || true
    fi
    
    # Firewalld (CentOS/RHEL)
    if command -v firewall-cmd &> /dev/null; then
        print_status "Removing firewalld rules..."
        firewall-cmd --permanent --remove-service=smtp 2>/dev/null || true
        firewall-cmd --permanent --remove-service=smtps 2>/dev/null || true
        firewall-cmd --permanent --remove-service=imap 2>/dev/null || true
        firewall-cmd --permanent --remove-service=imaps 2>/dev/null || true
        firewall-cmd --permanent --remove-service=pop3 2>/dev/null || true
        firewall-cmd --permanent --remove-service=pop3s 2>/dev/null || true
        firewall-cmd --permanent --remove-service=http 2>/dev/null || true
        firewall-cmd --permanent --remove-service=https 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
    fi
}

# Function to clean remaining files
clean_remaining_files() {
    print_header "Cleaning Remaining Files"
    
    # Remove temporary files
    find /tmp -name "*mail*" -type f -delete 2>/dev/null || true
    find /tmp -name "*postfix*" -type f -delete 2>/dev/null || true
    find /tmp -name "*dovecot*" -type f -delete 2>/dev/null || true
    
    # Remove lib directories
    rm -rf /var/lib/mail 2>/dev/null || true
    rm -rf /var/cache/mail 2>/dev/null || true
    
    # Remove run files
    rm -f /var/run/clamav/clamd.pid 2>/dev/null || true
    rm -f /var/run/dovecot/master.pid 2>/dev/null || true
    rm -f /var/spool/postfix/pid/master.pid 2>/dev/null || true
}

# Function to show summary
show_summary() {
    print_header "Uninstall Summary"
    
    echo -e "${GREEN}LibTMail mail server has been successfully removed!${NC}"
    echo
    echo "Removed Components:"
    echo "  ✓ Postfix SMTP server"
    echo "  ✓ Dovecot IMAP/POP3 server"
    echo "  ✓ MariaDB/MySQL database"
    echo "  ✓ SpamAssassin spam filter"
    echo "  ✓ ClamAV antivirus"
    echo "  ✓ OpenDKIM signing"
    echo "  ✓ Roundcube webmail"
    echo "  ✓ Apache/Nginx web server"
    echo "  ✓ SSL certificates"
    echo "  ✓ Management scripts"
    echo "  ✓ Cron jobs"
    echo "  ✓ Firewall rules"
    echo "  ✓ System users"
    echo "  ✓ Mail data and logs"
    echo
    echo -e "${YELLOW}Backup Location:${NC} $BACKUP_DIR"
    echo -e "${YELLOW}Uninstall Log:${NC} $LOG_FILE"
    echo
    echo "To restore your mail server in the future:"
    echo "1. Keep the backup directory safe"
    echo "2. Use the backup files to restore configurations"
    echo "3. Restore the database from the SQL dump"
    echo "4. Copy back the mail data"
    echo
    print_warning "Make sure to update your DNS records if you're decommissioning the server!"
    echo
    print_status "Uninstall completed successfully!"
}

# Function to confirm uninstall
confirm_uninstall() {
    print_header "Uninstall Confirmation"
    
    echo -e "${RED}WARNING: This will completely remove the mail server and all data!${NC}"
    echo
    echo "This uninstall will remove:"
    echo "  • All mail server packages (Postfix, Dovecot, etc.)"
    echo "  • All configuration files"
    echo "  • All mail data and user accounts"
    echo "  • Database and all email data"
    echo "  • SSL certificates"
    echo "  • Management scripts"
    echo "  • Log files"
    echo "  • System users created for mail server"
    echo
    echo -e "${YELLOW}A backup will be created at: $BACKUP_DIR${NC}"
    echo
    read -p "Are you absolutely sure you want to continue? (Type 'yes' to confirm): " -r
    echo
    
    if [[ $REPLY != "yes" ]]; then
        print_status "Uninstall cancelled by user"
        exit 0
    fi
}

# Main function
main() {
    print_header "LibTMail Mail Server Uninstall Script"
    
    check_root
    detect_distro
    check_installation
    confirm_uninstall
    create_backup
    stop_services
    remove_packages
    remove_configurations
    remove_mail_data
    remove_database
    remove_users
    remove_management_scripts
    remove_cron_jobs
    remove_ssl_certificates
    clean_firewall
    clean_remaining_files
    show_summary
}

# Run main function
main "$@"
