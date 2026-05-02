# Copyright (c) 2026 tda_45
# Bu proje TLİ (Türk Lisans İmzası) v1.0 ile lisanslanmıştır.
# Detaylar için LICENSE dosyasına bakınız.

#!/bin/bash

# Mail Server Configuration Script
# This script configures a complete mail server on Linux systems
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
DOMAIN=""
HOSTNAME=""
ADMIN_EMAIL=""
MYSQL_ROOT_PASSWORD=""
MYSQL_MAIL_PASSWORD=""
SSL_CERT_PATH="/etc/ssl/certs"
SSL_KEY_PATH="/etc/ssl/private"

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

# Function to update system packages
update_system() {
    print_header "Updating System Packages"
    
    case $DISTRO in
        ubuntu|debian)
            apt update && apt upgrade -y
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                dnf update -y
            else
                yum update -y
            fi
            ;;
        *)
            print_error "Unsupported distribution: $DISTRO"
            exit 1
            ;;
    esac
}

# Function to install basic packages
install_basic_packages() {
    print_header "Installing Basic Packages"
    
    case $DISTRO in
        ubuntu|debian)
            apt install -y wget curl git vim htop unzip bzip2 \
                software-properties-common apt-transport-https \
                ca-certificates gnupg lsb-release
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                dnf install -y wget curl git vim htop unzip bzip2
            else
                yum install -y wget curl git vim htop unzip bzip2
            fi
            ;;
    esac
}

# Function to get user input
get_user_input() {
    print_header "Configuration Parameters"
    
    echo "Please enter the following information:"
    echo
    
    # Get domain name
    while true; do
        read -p "Enter your domain name (e.g., example.com): " DOMAIN
        if [[ -n "$DOMAIN" && "$DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            print_error "Please enter a valid domain name"
        fi
    done
    
    # Get hostname
    read -p "Enter hostname (e.g., mail): " HOSTNAME
    HOSTNAME=${HOSTNAME:-mail}
    
    # Get admin email
    while true; do
        read -p "Enter admin email address: " ADMIN_EMAIL
        if [[ -n "$ADMIN_EMAIL" && "$ADMIN_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            print_error "Please enter a valid email address"
        fi
    done
    
    # Generate random passwords
    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
    MYSQL_MAIL_PASSWORD=$(openssl rand -base64 32)
    
    print_status "Generated MySQL passwords"
    print_warning "Save these passwords securely!"
    echo "MySQL Root Password: $MYSQL_ROOT_PASSWORD"
    echo "MySQL Mail Password: $MYSQL_MAIL_PASSWORD"
    echo
    read -p "Press Enter to continue..."
}

# Function to install MySQL/MariaDB
install_database() {
    print_header "Installing Database Server"
    
    case $DISTRO in
        ubuntu|debian)
            apt install -y mariadb-server mariadb-client
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                dnf install -y mariadb-server mariadb
            else
                yum install -y mariadb-server mariadb
            fi
            ;;
    esac
    
    # Start and enable database service
    systemctl enable mariadb
    systemctl start mariadb
    
    # Secure MySQL installation
    mysql -e "UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PASSWORD') WHERE User='root';"
    mysql -e "DELETE FROM mysql.user WHERE User='';"
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -e "DROP DATABASE IF EXISTS test;"
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    mysql -e "FLUSH PRIVILEGES;"
    
    print_status "Database server installed and secured"
}

# Function to create mail database
create_mail_database() {
    print_header "Creating Mail Database"
    
    # Create database and user
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS mailserver;"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER IF NOT EXISTS 'mailuser'@'localhost' IDENTIFIED BY '$MYSQL_MAIL_PASSWORD';"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON mailserver.* TO 'mailuser'@'localhost';"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"
    
    # Create tables
    mysql -u mailuser -p"$MYSQL_MAIL_PASSWORD" mailserver << EOF
CREATE TABLE IF NOT EXISTS domains (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain_id INT NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    FOREIGN KEY (domain_id) REFERENCES domains(id)
);

CREATE TABLE IF NOT EXISTS aliases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain_id INT NOT NULL,
    source VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    FOREIGN KEY (domain_id) REFERENCES domains(id)
);

INSERT INTO domains (name) VALUES ('$DOMAIN');
EOF
    
    print_status "Mail database created successfully"
}

# Function to install Postfix
install_postfix() {
    print_header "Installing Postfix"
    
    case $DISTRO in
        ubuntu|debian)
            export DEBIAN_FRONTEND=noninteractive
            apt install -y postfix postfix-mysql
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                dnf install -y postfix postfix-mysql
            else
                yum install -y postfix postfix-mysql
            fi
            ;;
    esac
    
    print_status "Postfix installed"
}

# Function to configure Postfix
configure_postfix() {
    print_header "Configuring Postfix"
    
    # Backup original configuration
    cp /etc/postfix/main.cf /etc/postfix/main.cf.backup
    
    # Create Postfix configuration
    cat > /etc/postfix/main.cf << EOF
# Basic settings
myhostname = ${HOSTNAME}.${DOMAIN}
mydomain = $DOMAIN
myorigin = \$mydomain
inet_interfaces = all
inet_protocols = all
mydestination = localhost, localhost.\$mydomain

# Virtual domains and users
virtual_mailbox_domains = mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
virtual_mailbox_maps = mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
virtual_alias_maps = mysql:/etc/postfix/mysql-virtual-alias-maps.cf

# Mailbox location
virtual_mailbox_base = /var/vmail
virtual_minimum_uid = 5000
virtual_uid_maps = static:5000
virtual_gid_maps = static:5000

# SMTP authentication
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination

# TLS settings
smtpd_tls_cert_file = $SSL_CERT_PATH/mailserver.crt
smtpd_tls_key_file = $SSL_KEY_PATH/mailserver.key
smtpd_use_tls = yes
smtpd_tls_auth_only = yes

# Message size limit
message_size_limit = 52428800
mailbox_size_limit = 0

# Network settings
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
EOF

    # Create MySQL configuration files
    cat > /etc/postfix/mysql-virtual-mailbox-domains.cf << EOF
user = mailuser
password = $MYSQL_MAIL_PASSWORD
hosts = localhost
dbname = mailserver
query = SELECT 1 FROM domains WHERE name='%s'
EOF

    cat > /etc/postfix/mysql-virtual-mailbox-maps.cf << EOF
user = mailuser
password = $MYSQL_MAIL_PASSWORD
hosts = localhost
dbname = mailserver
query = SELECT 1 FROM users WHERE email='%s'
EOF

    cat > /etc/postfix/mysql-virtual-alias-maps.cf << EOF
user = mailuser
password = $MYSQL_MAIL_PASSWORD
hosts = localhost
dbname = mailserver
query = SELECT destination FROM aliases WHERE source='%s'
EOF

    # Set proper permissions
    chmod 640 /etc/postfix/mysql-*.cf
    chown postfix:postfix /etc/postfix/mysql-*.cf
    
    # Create vmail user and directory
    useradd -r -u 5000 -g mail -d /var/vmail -s /sbin/nologin vmail || true
    mkdir -p /var/vmail
    chown -R vmail:mail /var/vmail
    
    print_status "Postfix configured"
}

# Function to install Dovecot
install_dovecot() {
    print_header "Installing Dovecot"
    
    case $DISTRO in
        ubuntu|debian)
            apt install -y dovecot-core dovecot-imapd dovecot-pop3d dovecot-mysql
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                dnf install -y dovecot dovecot-mysql
            else
                yum install -y dovecot dovecot-mysql
            fi
            ;;
    esac
    
    print_status "Dovecot installed"
}

# Function to configure Dovecot
configure_dovecot() {
    print_header "Configuring Dovecot"
    
    # Backup configurations
    cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.backup
    
    # Configure main Dovecot
    cat > /etc/dovecot/dovecot.conf << EOF
!include conf.d/*.conf

protocols = imap pop3 lmtp
listen = *
base_dir = /var/run/dovecot/

instance_name = dovecot

login_greeting = Dovecot ready.

mail_location = maildir:/var/vmail/%d/%n

mail_privileged_group = mail

auth_mechanisms = plain login

passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}

userdb {
  driver = static
  args = uid=vmail gid=mail home=/var/vmail/%d/%n
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0666
    user = postfix
    group = postfix
  }
}

ssl = required
ssl_cert = <$SSL_CERT_PATH/mailserver.crt
ssl_key = <$SSL_KEY_PATH/mailserver.key
EOF

    # Configure SQL authentication
    cat > /etc/dovecot/dovecot-sql.conf.ext << EOF
driver = mysql
connect = host=localhost dbname=mailserver user=mailuser password=$MYSQL_MAIL_PASSWORD
default_pass_scheme = SHA512-CRYPT
password_query = SELECT email as user, password FROM users WHERE email='%u';
EOF

    # Set permissions
    chmod 640 /etc/dovecot/dovecot-sql.conf.ext
    chown root:dovecot /etc/dovecot/dovecot-sql.conf.ext
    
    print_status "Dovecot configured"
}

# Function to generate SSL certificate
generate_ssl_certificate() {
    print_header "Generating SSL Certificate"
    
    # Create directories if they don't exist
    mkdir -p $SSL_CERT_PATH
    mkdir -p $SSL_KEY_PATH
    
    # Generate self-signed certificate
    openssl req -new -x509 -days 365 -nodes \
        -out $SSL_CERT_PATH/mailserver.crt \
        -keyout $SSL_KEY_PATH/mailserver.key \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=IT Department/CN=${HOSTNAME}.${DOMAIN}"
    
    # Set permissions
    chmod 600 $SSL_KEY_PATH/mailserver.key
    chmod 644 $SSL_CERT_PATH/mailserver.crt
    
    print_status "SSL certificate generated"
}

# Function to configure firewall
configure_firewall() {
    print_header "Configuring Firewall"
    
    # Open necessary ports
    if command -v ufw &> /dev/null; then
        # Ubuntu/Debian with UFW
        ufw allow 25/tcp    # SMTP
        ufw allow 587/tcp   # SMTPS
        ufw allow 465/tcp   # SMTPS
        ufw allow 143/tcp   # IMAP
        ufw allow 993/tcp   # IMAPS
        ufw allow 110/tcp   # POP3
        ufw allow 995/tcp   # POP3S
        ufw --force enable
        print_status "UFW firewall configured"
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS/RHEL with firewalld
        firewall-cmd --permanent --add-service=smtp
        firewall-cmd --permanent --add-service=smtps
        firewall-cmd --permanent --add-service=imap
        firewall-cmd --permanent --add-service=imaps
        firewall-cmd --permanent --add-service=pop3
        firewall-cmd --permanent --add-service=pop3s
        firewall-cmd --reload
        print_status "Firewalld configured"
    else
        print_warning "No firewall management tool found. Please manually open ports: 25, 587, 465, 143, 993, 110, 995"
    fi
}

# Function to start services
start_services() {
    print_header "Starting Services"
    
    # Start and enable services
    systemctl enable postfix
    systemctl start postfix
    
    systemctl enable dovecot
    systemctl start dovecot
    
    # Check service status
    if systemctl is-active --quiet postfix; then
        print_status "Postfix is running"
    else
        print_error "Postfix failed to start"
    fi
    
    if systemctl is-active --quiet dovecot; then
        print_status "Dovecot is running"
    else
        print_error "Dovecot failed to start"
    fi
}

# Function to create admin user
create_admin_user() {
    print_header "Creating Admin Email User"
    
    # Generate password for admin user
    ADMIN_PASSWORD=$(openssl rand -base64 16)
    
    # Hash password
    PASSWORD_HASH=$(doveadm pw -s SHA512-CRYPT -p "$ADMIN_PASSWORD")
    
    # Insert admin user into database
    mysql -u mailuser -p"$MYSQL_MAIL_PASSWORD" mailserver << EOF
INSERT INTO users (domain_id, email, password) 
VALUES (1, '$ADMIN_EMAIL', '$PASSWORD_HASH');
EOF
    
    print_status "Admin email user created"
    print_warning "Admin Email: $ADMIN_EMAIL"
    print_warning "Admin Password: $ADMIN_PASSWORD"
    echo "Please save these credentials securely!"
}

# Function to create user management script
create_user_management_script() {
    print_header "Creating User Management Script"
    
    cat > /usr/local/bin/mailadmin << 'EOF'
#!/bin/bash

# Mail User Management Script

DOMAIN=$(mysql -u mailuser -p$(cat /etc/mysql/mail_password) mailserver -e "SELECT name FROM domains LIMIT 1;" -s -N)

add_user() {
    local email=$1
    local password=$2
    
    if [[ -z "$email" || -z "$password" ]]; then
        echo "Usage: $0 add <email> <password>"
        exit 1
    fi
    
    # Hash password
    local password_hash=$(doveadm pw -s SHA512-CRYPT -p "$password")
    
    # Insert user
    mysql -u mailuser -p$(cat /etc/mysql/mail_password) mailserver << SQL
INSERT INTO users (domain_id, email, password) 
VALUES ((SELECT id FROM domains WHERE name='$DOMAIN'), '$email', '$password_hash');
SQL
    
    echo "User $email added successfully"
}

delete_user() {
    local email=$1
    
    if [[ -z "$email" ]]; then
        echo "Usage: $0 delete <email>"
        exit 1
    fi
    
    mysql -u mailuser -p$(cat /etc/mysql/mail_password) mailserver << SQL
DELETE FROM users WHERE email='$email';
SQL
    
    echo "User $email deleted successfully"
}

list_users() {
    echo "Email users for domain $DOMAIN:"
    mysql -u mailuser -p$(cat /etc/mysql/mail_password) mailserver -e "SELECT email FROM users;" -s -N
}

change_password() {
    local email=$1
    local password=$2
    
    if [[ -z "$email" || -z "$password" ]]; then
        echo "Usage: $0 password <email> <new_password>"
        exit 1
    fi
    
    # Hash password
    local password_hash=$(doveadm pw -s SHA512-CRYPT -p "$password")
    
    mysql -u mailuser -p$(cat /etc/mysql/mail_password) mailserver << SQL
UPDATE users SET password='$password_hash' WHERE email='$email';
SQL
    
    echo "Password changed for $email"
}

case "$1" in
    add)
        add_user "$2" "$3"
        ;;
    delete)
        delete_user "$2"
        ;;
    list)
        list_users
        ;;
    password)
        change_password "$2" "$3"
        ;;
    *)
        echo "Usage: $0 {add|delete|list|password}"
        echo "  add <email> <password>     - Add new user"
        echo "  delete <email>             - Delete user"
        echo "  list                       - List all users"
        echo "  password <email> <pass>    - Change user password"
        exit 1
        ;;
esac
EOF

    chmod +x /usr/local/bin/mailadmin
    
    # Save MySQL password for the script
    echo "$MYSQL_MAIL_PASSWORD" > /etc/mysql/mail_password
    chmod 600 /etc/mysql/mail_password
    
    print_status "User management script created: /usr/local/bin/mailadmin"
}

# Function to test configuration
test_configuration() {
    print_header "Testing Configuration"
    
    # Test Postfix
    print_status "Testing Postfix configuration..."
    if postfix check; then
        print_status "Postfix configuration is valid"
    else
        print_error "Postfix configuration has errors"
    fi
    
    # Test Dovecot
    print_status "Testing Dovecot configuration..."
    if doveconf -n > /dev/null 2>&1; then
        print_status "Dovecot configuration is valid"
    else
        print_error "Dovecot configuration has errors"
    fi
    
    # Test ports
    print_status "Checking open ports..."
    netstat -tlnp | grep -E ':(25|587|143|993|110|995)\s'
}

# Function to install SpamAssassin
install_spamassassin() {
    print_header "Installing SpamAssassin"
    
    case $DISTRO in
        ubuntu|debian)
            apt install -y spamassassin spamc
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                dnf install -y spamassassin
            else
                yum install -y spamassassin
            fi
            ;;
    esac
    
    # Create spamassassin user
    useradd -r -s /bin/false spamd || true
    
    # Configure SpamAssassin
    cat > /etc/spamassassin/local.cf << EOF
# SpamAssassin configuration
rewrite_header Subject [SPAM]
required_score 5.0
use_bayes 1
bayes_auto_learn 1
bayes_auto_expire 1
bayes_min_spam_num 200
bayes_min_ham_num 200
use_dcc 1
use_pyzor 1
use_razor2 1
use_dkim 1
score SPF_FAIL 10.0
score SPF_HELO_FAIL 8.0
score DKIM_VERIFICATION_FAILED 5.0
score DKIM_ADSP_NXDOMAIN 5.0
score RAZOR2_CHECK 2.5
score PYZOR_CHECK 2.5
score DCC_CHECK 2.5
score BAYES_99 4.0
score BAYES_00 -3.0
EOF
    
    # Enable and start SpamAssassin
    systemctl enable spamassassin
    systemctl start spamassassin
    
    print_status "SpamAssassin installed and configured"
}

# Function to install ClamAV
install_clamav() {
    print_header "Installing ClamAV Antivirus"
    
    case $DISTRO in
        ubuntu|debian)
            apt install -y clamav clamav-freshclam clamsmtp
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                dnf install -y clamav clamav-update clamsmtp
            else
                yum install -y clamav clamav-update clamsmtp
            fi
            ;;
    esac
    
    # Stop freshclam to update
    systemctl stop freshclam
    
    # Update virus definitions
    freshclam
    
    # Configure ClamAV
    cat > /etc/clamav/clamd.conf << EOF
# ClamAV configuration
LogFile /var/log/clamav/clamd.log
LogTime yes
DatabaseDirectory /var/lib/clamav
PidFile /var/run/clamav/clamd.pid
TemporaryDirectory /tmp
LocalSocket /var/run/clamav/clamd.sock
User clamav
ScanMail yes
ScanArchive yes
ArchiveBlockEncrypted no
MaxScanSize 100M
MaxFileSize 25M
EOF
    
    # Configure freshclam
    cat > /etc/clamav/freshclam.conf << EOF
# Freshclam configuration
DatabaseDirectory /var/lib/clamav
UpdateLogFile /var/log/clamav/freshclam.log
PidFile /var/run/clamav/freshclam.pid
DatabaseOwner clamav
DatabaseMirror database.clamav.net
Checks 24
EOF
    
    # Enable and start services
    systemctl enable clamav-freshclam
    systemctl start clamav-freshclam
    systemctl enable clamav-daemon
    systemctl start clamav-daemon
    
    print_status "ClamAV installed and configured"
}

# Function to install OpenDKIM
install_opendkim() {
    print_header "Installing OpenDKIM"
    
    case $DISTRO in
        ubuntu|debian)
            apt install -y opendkim opendkim-tools
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                dnf install -y opendkim
            else
                yum install -y opendkim
            fi
            ;;
    esac
    
    # Create directories
    mkdir -p /etc/opendkim/keys/$DOMAIN
    
    # Generate keys
    opendkim-genkey -s mail -d $DOMAIN -D /etc/opendkim/keys/$DOMAIN
    chown opendkim:opendkim /etc/opendkim/keys/$DOMAIN/mail.private
    chmod 600 /etc/opendkim/keys/$DOMAIN/mail.private
    
    # Configure OpenDKIM
    cat > /etc/opendkim.conf << EOF
# OpenDKIM configuration
Syslog yes
UMask 002
Mode sv
Canonicalization relaxed/simple
ExternalIgnoreList refile:/etc/opendkim/TrustedHosts
InternalHosts refile:/etc/opendkim/TrustedHosts
KeyTable refile:/etc/opendkim/KeyTable
SigningTable refile:/etc/opendkim/SigningTable
PidFile /var/run/opendkim/opendkim.pid
Socket inet:12301@localhost
EOF
    
    # Create TrustedHosts file
    cat > /etc/opendkim/TrustedHosts << EOF
127.0.0.1
localhost
192.168.0.0/16
10.0.0.0/8
172.16.0.0/12
*.$DOMAIN
EOF
    
    # Create KeyTable file
    cat > /etc/opendkim/KeyTable << EOF
mail._domainkey.$DOMAIN $DOMAIN:mail:/etc/opendkim/keys/$DOMAIN/mail.private
EOF
    
    # Create SigningTable file
    cat > /etc/opendkim/SigningTable << EOF
*@$DOMAIN mail._domainkey.$DOMAIN
EOF
    
    # Enable and start OpenDKIM
    systemctl enable opendkim
    systemctl start opendkim
    
    print_status "OpenDKIM installed and configured"
    print_warning "Add this DNS TXT record for DKIM:"
    cat /etc/opendkim/keys/$DOMAIN/mail.txt
}

# Function to install Roundcube webmail
install_roundcube() {
    print_header "Installing Roundcube Webmail"
    
    case $DISTRO in
        ubuntu|debian)
            apt install -y apache2 php php-mysql php-imap php-json php-curl php-xml php-mbstring php-intl php-gd php-zip php-bz2 php-ldap
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                dnf install -y httpd php php-mysqlnd php-imap php-json php-curl php-xml php-mbstring php-intl php-gd php-zip php-bzip2 php-ldap
            else
                yum install -y httpd php php-mysql php-imap php-json php-curl php-xml php-mbstring php-intl php-gd php-zip php-bzip2 php-ldap
            fi
            ;;
    esac
    
    # Download Roundcube
    cd /tmp
    wget https://github.com/roundcube/roundcubemail/releases/download/1.6.2/roundcubemail-1.6.2-complete.tar.gz
    tar -xzf roundcubemail-1.6.2-complete.tar.gz
    mv roundcubemail-1.6.2 /var/www/html/webmail
    
    # Set permissions
    chown -R www-data:www-data /var/www/html/webmail
    chmod -R 755 /var/www/html/webmail
    
    # Create Apache configuration
    cat > /etc/apache2/sites-available/webmail.conf << EOF
<VirtualHost *:80>
    ServerName ${HOSTNAME}.${DOMAIN}
    DocumentRoot /var/www/html/webmail
    
    <Directory /var/www/html/webmail>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/webmail_error.log
    CustomLog \${APACHE_LOG_DIR}/webmail_access.log combined
</VirtualHost>
EOF
    
    # Enable site and modules
    a2ensite webmail.conf
    a2enmod rewrite
    a2enmod ssl
    
    # Enable and start Apache
    systemctl enable apache2
    systemctl restart apache2
    
    print_status "Roundcube webmail installed"
    print_warning "Complete webmail setup at: http://${HOSTNAME}.${DOMAIN}/webmail/installer"
}

# Function to create backup script
create_backup_script() {
    print_header "Creating Backup Script"
    
    cat > /usr/local/bin/mailbackup << 'EOF'
#!/bin/bash

# Mail Server Backup Script
BACKUP_DIR="/var/backups/mailserver"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/mailserver_backup_$DATE.tar.gz"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup databases
mysqldump --single-transaction --routines --triggers mailserver > $BACKUP_DIR/mailserver_$DATE.sql

# Backup configurations
tar -czf $BACKUP_DIR/configs_$DATE.tar.gz /etc/postfix /etc/dovecot /etc/opendkim /etc/spamassassin /etc/clamav

# Backup mail data
tar -czf $BACKUP_DIR/maildata_$DATE.tar.gz /var/vmail

# Backup SSL certificates
cp -r /etc/ssl/certs $BACKUP_DIR/ssl_certs_$DATE
cp -r /etc/ssl/private $BACKUP_DIR/ssl_private_$DATE

# Create combined backup
tar -czf $BACKUP_FILE $BACKUP_DIR/*_$DATE.*

# Clean up old backups (keep last 7 days)
find $BACKUP_DIR -name "mailserver_backup_*.tar.gz" -mtime +7 -delete
find $BACKUP_DIR -name "*_backup_*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "configs_*.tar.gz" -mtime +7 -delete
find $BACKUP_DIR -name "maildata_*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_FILE"
EOF
    
    chmod +x /usr/local/bin/mailbackup
    
    # Create cron job for daily backups
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/mailbackup") | crontab -
    
    print_status "Backup script created: /usr/local/bin/mailbackup"
    print_status "Daily backup scheduled at 2:00 AM"
}

# Function to create monitoring script
create_monitoring_script() {
    print_header "Creating Monitoring Script"
    
    cat > /usr/local/bin/mailmonitor << 'EOF'
#!/bin/bash

# Mail Server Monitoring Script
LOG_FILE="/var/log/mailserver_monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Function to log messages
log_message() {
    echo "$DATE - $1" >> $LOG_FILE
}

# Check service status
check_service() {
    local service=$1
    if systemctl is-active --quiet $service; then
        log_message "OK: $service is running"
        return 0
    else
        log_message "ERROR: $service is not running"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    local usage=$(df /var/vmail | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ $usage -gt 80 ]; then
        log_message "WARNING: Mail disk usage is ${usage}%"
    else
        log_message "OK: Mail disk usage is ${usage}%"
    fi
}

# Check mail queue
check_mail_queue() {
    local queue_size=$(mailq | grep -c '^[A-F0-9]')
    if [ $queue_size -gt 100 ]; then
        log_message "WARNING: Mail queue has $queue_size messages"
    else
        log_message "OK: Mail queue has $queue_size messages"
    fi
}

# Run checks
log_message "Starting mail server monitoring"

check_service postfix
check_service dovecot
check_service mariadb
check_service spamassassin
check_service clamav-daemon
check_service opendkim

check_disk_space
check_mail_queue

log_message "Monitoring completed"
EOF
    
    chmod +x /usr/local/bin/mailmonitor
    
    # Create cron job for monitoring (every 5 minutes)
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/mailmonitor") | crontab -
    
    print_status "Monitoring script created: /usr/local/bin/mailmonitor"
    print_status "Monitoring scheduled every 5 minutes"
}

# Function to create mail queue management script
create_queue_management_script() {
    print_header "Creating Queue Management Script"
    
    cat > /usr/local/bin/mailqueue << 'EOF'
#!/bin/bash

# Mail Queue Management Script

show_queue() {
    echo "Mail Queue Status:"
    mailq
}

flush_queue() {
    echo "Flushing mail queue..."
    postfix flush
    echo "Queue flushed."
}

delete_queue() {
    echo "Deleting all queued messages..."
    postsuper -d ALL
    echo "All queued messages deleted."
}

delete_deferred() {
    echo "Deleting deferred messages..."
    postsuper -d deferred
    echo "Deferred messages deleted."
}

show_queue_stats() {
    echo "Queue Statistics:"
    echo "Active: $(mailq | grep -c '^[A-F0-9]')"
    echo "Deferred: $(mailq | grep -c '^[A-F0-9]' | wc -l)"
    echo "Hold: $(mailq | grep -c '^[A-F0-9]' | wc -l)"
}

requeue_messages() {
    echo "Requeuing deferred messages..."
    postsuper -r deferred
    echo "Messages requeued."
}

case "$1" in
    show)
        show_queue
        ;;
    flush)
        flush_queue
        ;;
    delete)
        delete_queue
        ;;
    deferred)
        delete_deferred
        ;;
    stats)
        show_queue_stats
        ;;
    requeue)
        requeue_messages
        ;;
    *)
        echo "Usage: $0 {show|flush|delete|deferred|stats|requeue}"
        echo "  show     - Show mail queue"
        echo "  flush    - Flush mail queue"
        echo "  delete   - Delete all queued messages"
        echo "  deferred - Delete deferred messages"
        echo "  stats    - Show queue statistics"
        echo "  requeue  - Requeue deferred messages"
        exit 1
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/mailqueue
    
    print_status "Queue management script created: /usr/local/bin/mailqueue"
}

# Function to integrate security features with Postfix
integrate_security_features() {
    print_header "Integrating Security Features with Postfix"
    
    # Add SpamAssassin integration
    cat >> /etc/postfix/main.cf << EOF

# SpamAssassin integration
content_filter = spamassassin
spamassassin unix -     n       n       -       -       pipe
    user=spamd argv=/usr/bin/spamc -f -e /usr/sbin/sendmail -oi -f \${sender} \${recipient}
EOF
    
    # Add ClamAV integration
    cat >> /etc/postfix/main.cf << EOF

# ClamAV integration
content_filter = scan:[127.0.0.1]:10026
receive_override_options = no_address_mappings
EOF
    
    # Configure ClamAV for Postfix
    cat > /etc/clamav/clamsmtpd.conf << EOF
# ClamSMTP configuration
OutAddress 10025
Listen 127.0.0.1:10026
ClamAddress /var/run/clamav/clamd.sock
Header X-Virus-Scanned: ClamAV using ClamSMTP
TempDirectory /var/tmp
Action quarantine
User clamav
EOF
    
    # Enable and start clamsmtp
    systemctl enable clamsmtp
    systemctl start clamsmtp
    
    # Add OpenDKIM integration
    cat >> /etc/postfix/main.cf << EOF

# OpenDKIM integration
milter_protocol = 2
milter_default_action = accept
smtpd_milters = inet:localhost:12301
non_smtpd_milters = inet:localhost:12301
EOF
    
    # Restart Postfix to apply changes
    systemctl restart postfix
    
    print_status "Security features integrated with Postfix"
}

# Function to display final information
display_final_info() {
    print_header "Installation Complete!"
    
    echo -e "${GREEN}Your mail server has been successfully configured with advanced features!${NC}"
    echo
    echo "Server Information:"
    echo "  Domain: $DOMAIN"
    echo "  Hostname: ${HOSTNAME}.${DOMAIN}"
    echo "  Admin Email: $ADMIN_EMAIL"
    echo
    echo "Service Status:"
    echo "  Postfix: $(systemctl is-active postfix)"
    echo "  Dovecot: $(systemctl is-active dovecot)"
    echo "  MariaDB: $(systemctl is-active mariadb)"
    echo "  SpamAssassin: $(systemctl is-active spamassassin)"
    echo "  ClamAV: $(systemctl is-active clamav-daemon)"
    echo "  OpenDKIM: $(systemctl is-active opendkim)"
    echo "  Apache: $(systemctl is-active apache2)"
    echo
    echo "Open Ports:"
    echo "  25   - SMTP"
    echo "  587  - SMTP (Submission)"
    echo "  143  - IMAP"
    echo "  993  - IMAPS"
    echo "  110  - POP3"
    echo "  995  - POP3S"
    echo "  80   - HTTP (Webmail)"
    echo "  443  - HTTPS (Webmail)"
    echo
    echo "Management Tools:"
    echo "  mailadmin     - Manage email users"
    echo "  mailbackup    - Backup mail server"
    echo "  mailmonitor   - Monitor services"
    echo "  mailqueue     - Manage mail queue"
    echo
    echo "Webmail Interface:"
    echo "  http://${HOSTNAME}.${DOMAIN}/webmail"
    echo
    echo "Security Features:"
    echo "  ✓ Spam filtering with SpamAssassin"
    echo "  ✓ Virus scanning with ClamAV"
    echo "  ✓ DKIM signing with OpenDKIM"
    echo "  ✓ SSL/TLS encryption"
    echo "  ✓ Firewall configuration"
    echo
    echo "Important Files:"
    echo "  Postfix config: /etc/postfix/main.cf"
    echo "  Dovecot config: /etc/dovecot/dovecot.conf"
    echo "  SpamAssassin config: /etc/spamassassin/local.cf"
    echo "  ClamAV config: /etc/clamav/clamd.conf"
    echo "  OpenDKIM config: /etc/opendkim.conf"
    echo "  SSL Certificate: $SSL_CERT_PATH/mailserver.crt"
    echo "  SSL Key: $SSL_KEY_PATH/mailserver.key"
    echo "  Backup directory: /var/backups/mailserver"
    echo "  Monitoring log: /var/log/mailserver_monitor.log"
    echo
    echo "Next Steps:"
    echo "1. Configure DNS MX records to point to your server"
    echo "2. Add DKIM TXT record to your DNS (shown above)"
    echo "3. Configure SPF and DMARC records"
    echo "4. Complete webmail setup at: http://${HOSTNAME}.${DOMAIN}/webmail/installer"
    echo "5. Test email functionality"
    echo "6. Set up regular monitoring"
    echo "7. Configure backup retention policy"
    echo
    echo "Example DNS Records:"
    echo "  MX    @    10    ${HOSTNAME}.${DOMAIN}"
    echo "  TXT   @    "v=spf1 mx -all""
    echo "  TXT   mail._domainkey    "$(cat /etc/opendkim/keys/$DOMAIN/mail.txt | grep -o '".*"' | tr -d '"')""
    echo "  TXT   _dmarc    "v=DMARC1; p=quarantine; rua=mailto:dmarc@${DOMAIN}""
    echo
    print_warning "Remember to save your MySQL passwords securely!"
    print_warning "Complete webmail installation through the web interface!"
}

# Main function
main() {
    print_header "Mail Server Configuration Script"
    
    check_root
    detect_distro
    update_system
    install_basic_packages
    get_user_input
    install_database
    create_mail_database
    install_postfix
    configure_postfix
    install_dovecot
    configure_dovecot
    generate_ssl_certificate
    configure_firewall
    install_spamassassin
    install_clamav
    install_opendkim
    install_roundcube
    integrate_security_features
    start_services
    create_admin_user
    create_user_management_script
    create_backup_script
    create_monitoring_script
    create_queue_management_script
    test_configuration
    display_final_info
    
    print_status "Advanced mail server configuration completed successfully!"
}

# Run main function
main "$@"
