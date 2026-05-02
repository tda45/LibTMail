#!/bin/bash

# LibTMail Docker Entrypoint Script
# Initializes and starts the mail server services
# Author: tda_45
# Version: 1.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check if this is the first run
is_first_run() {
    if [[ ! -f /var/lib/mysql/.first_run_complete ]]; then
        return 0
    else
        return 1
    fi
}

# Function to generate random passwords
generate_passwords() {
    if is_first_run; then
        print_header "Generating Random Passwords"
        
        if [[ -z "$MYSQL_ROOT_PASSWORD" || "$MYSQL_ROOT_PASSWORD" == "changeme" ]]; then
            MYSQL_ROOT_PASSWORD=$(pwgen -s 32 1)
            print_warning "Generated MySQL root password: $MYSQL_ROOT_PASSWORD"
        fi
        
        if [[ -z "$MYSQL_MAIL_PASSWORD" || "$MYSQL_MAIL_PASSWORD" == "changeme" ]]; then
            MYSQL_MAIL_PASSWORD=$(pwgen -s 32 1)
            print_warning "Generated MySQL mail password: $MYSQL_MAIL_PASSWORD"
        fi
        
        # Save passwords to file
        echo "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD" > /etc/mailserver/.env
        echo "MYSQL_MAIL_PASSWORD=$MYSQL_MAIL_PASSWORD" >> /etc/mailserver/.env
        chmod 600 /etc/mailserver/.env
        
        print_status "Passwords saved to /etc/mailserver/.env"
    fi
}

# Function to initialize MySQL
initialize_mysql() {
    if is_first_run; then
        print_header "Initializing MySQL"
        
        # Start MySQL service
        service mysql start
        
        # Wait for MySQL to be ready
        while ! mysqladmin ping --silent; do
            sleep 1
        done
        
        # Set root password
        mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
        
        # Remove anonymous users
        mysql -e "DELETE FROM mysql.user WHERE User='';"
        
        # Remove remote root access
        mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
        
        # Drop test database
        mysql -e "DROP DATABASE IF EXISTS test;"
        mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
        
        # Reload privileges
        mysql -e "FLUSH PRIVILEGES;"
        
        print_status "MySQL initialized"
    else
        # Start MySQL service
        service mysql start
    fi
}

# Function to configure database
configure_database() {
    if is_first_run; then
        print_header "Configuring Database"
        
        # Create mailserver database
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS mailserver;"
        
        # Create mailuser
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER IF NOT EXISTS 'mailuser'@'localhost' IDENTIFIED BY '$MYSQL_MAIL_PASSWORD';"
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON mailserver.* TO 'mailuser'@'localhost';"
        
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

INSERT INTO domains (name) VALUES ('$MAIL_DOMAIN');
EOF
        
        print_status "Database configured"
    fi
}

# Function to generate SSL certificates
generate_ssl_certificates() {
    if is_first_run; then
        print_header "Generating SSL Certificates"
        
        # Create directories
        mkdir -p /etc/ssl/certs
        mkdir -p /etc/ssl/private
        
        # Generate self-signed certificate
        openssl req -new -x509 -days 365 -nodes \
            -out /etc/ssl/certs/mailserver.crt \
            -keyout /etc/ssl/private/mailserver.key \
            -subj "/C=US/ST=State/L=City/O=Organization/OU=IT Department/CN=${MAIL_HOSTNAME}.${MAIL_DOMAIN}"
        
        # Set permissions
        chmod 600 /etc/ssl/private/mailserver.key
        chmod 644 /etc/ssl/certs/mailserver.crt
        
        print_status "SSL certificates generated"
    fi
}

# Function to create admin user
create_admin_user() {
    if is_first_run; then
        print_header "Creating Admin User"
        
        # Generate admin password
        ADMIN_PASSWORD=$(pwgen -s 16 1)
        
        # Hash password
        PASSWORD_HASH=$(doveadm pw -s SHA512-CRYPT -p "$ADMIN_PASSWORD")
        
        # Insert admin user
        mysql -u mailuser -p"$MYSQL_MAIL_PASSWORD" mailserver << EOF
INSERT INTO users (domain_id, email, password) 
VALUES (1, '$ADMIN_EMAIL', '$PASSWORD_HASH');
EOF
        
        print_status "Admin user created"
        print_warning "Admin Email: $ADMIN_EMAIL"
        print_warning "Admin Password: $ADMIN_PASSWORD"
        
        # Save admin credentials
        echo "ADMIN_EMAIL=$ADMIN_EMAIL" >> /etc/mailserver/.env
        echo "ADMIN_PASSWORD=$ADMIN_PASSWORD" >> /etc/mailserver/.env
    fi
}

# Function to configure services
configure_services() {
    print_header "Configuring Services"
    
    # Run configuration scripts
    /usr/local/bin/config-postfix.sh
    /usr/local/bin/config-dovecot.sh
    /usr/local/bin/config-opendkim.sh
    /usr/local/bin/config-spamassassin.sh
    /usr/local/bin/config-clamav.sh
    /usr/local/bin/config-apache.sh
    
    print_status "Services configured"
}

# Function to setup cron jobs
setup_cron() {
    print_header "Setting Up Cron Jobs"
    
    # Create cron jobs
    echo "0 2 * * * /usr/local/bin/mailbackup" >> /etc/crontab
    echo "*/5 * * * * /usr/local/bin/mailmonitor" >> /etc/crontab
    
    # Start cron service
    service cron start
    
    print_status "Cron jobs configured"
}

# Function to mark first run complete
mark_first_run_complete() {
    if is_first_run; then
        touch /var/lib/mysql/.first_run_complete
        print_status "First run marked complete"
    fi
}

# Function to show final information
show_final_info() {
    print_header "LibTMail Docker Container Started"
    
    echo -e "${GREEN}Your mail server is now running in Docker!${NC}"
    echo
    echo "Server Information:"
    echo "  Domain: $MAIL_DOMAIN"
    echo "  Hostname: ${MAIL_HOSTNAME}.${MAIL_DOMAIN}"
    echo "  Container: $(hostname)"
    echo
    echo "Services:"
    echo "  SMTP: 25, 587"
    echo "  IMAP: 143, 993"
    echo "  POP3: 110, 995"
    echo "  Webmail: http://localhost:80"
    echo "  HTTPS: https://localhost:443"
    echo
    echo "Management Commands:"
    echo "  docker exec libtmail mailadmin list"
    echo "  docker exec libtmail mailbackup"
    echo "  docker exec libtmail mailmonitor"
    echo "  docker exec libtmail mailqueue show"
    echo
    echo "Database Access:"
    echo "  phpMyAdmin: http://localhost:8080 (if enabled)"
    echo "  Host: libtmail"
    echo "  User: root / mailuser"
    echo
    
    if [[ -f /etc/mailserver/.env ]]; then
        echo "Credentials (saved in /etc/mailserver/.env):"
        cat /etc/mailserver/.env
    fi
    
    echo
    print_warning "Remember to configure your DNS MX records!"
}

# Function to handle signals
cleanup() {
    print_status "Received shutdown signal, stopping services..."
    supervisorctl stop all
    service mysql stop
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Main function
main() {
    print_header "LibTMail Docker Container Starting"
    
    # Check environment variables
    if [[ -z "$MAIL_DOMAIN" ]]; then
        print_warning "MAIL_DOMAIN not set, using default: example.com"
        export MAIL_DOMAIN=example.com
    fi
    
    if [[ -z "$MAIL_HOSTNAME" ]]; then
        print_warning "MAIL_HOSTNAME not set, using default: mail"
        export MAIL_HOSTNAME=mail
    fi
    
    if [[ -z "$ADMIN_EMAIL" ]]; then
        print_warning "ADMIN_EMAIL not set, using default: admin@example.com"
        export ADMIN_EMAIL=admin@example.com
    fi
    
    # Initialize if first run
    if is_first_run; then
        generate_passwords
        initialize_mysql
        configure_database
        generate_ssl_certificates
        create_admin_user
        configure_services
        setup_cron
        mark_first_run_complete
    else
        # Start existing services
        service mysql start
        service cron start
    fi
    
    # Show final information
    show_final_info
    
    # Start supervisor
    exec "$@"
}

# Run main function
main "$@"
