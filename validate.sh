#!/bin/bash

# LibTMail Configuration Validation Tool
# Validates mail server configuration and detects potential issues
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
VALIDATION_LOG="/tmp/libtmail_validation.log"
ISSUES_FOUND=0
WARNINGS_FOUND=0
CRITICAL_ERRORS=0

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$VALIDATION_LOG"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$VALIDATION_LOG"
    WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$VALIDATION_LOG"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS + 1))
}

print_header() {
    echo -e "${BLUE}================================${NC}" | tee -a "$VALIDATION_LOG"
    echo -e "${BLUE}$1${NC}" | tee -a "$VALIDATION_LOG"
    echo -e "${BLUE}================================${NC}" | tee -a "$VALIDATION_LOG"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to initialize validation
init_validation() {
    print_header "LibTMail Configuration Validation"
    
    > "$VALIDATION_LOG"
    echo "LibTMail Configuration Validation Report" | tee -a "$VALIDATION_LOG"
    echo "Date: $(date)" | tee -a "$VALIDATION_LOG"
    echo "Hostname: $(hostname)" | tee -a "$VALIDATION_LOG"
    echo "================================" | tee -a "$VALIDATION_LOG"
}

# Function to validate Postfix configuration
validate_postfix() {
    print_header "Validating Postfix Configuration"
    
    # Check if Postfix is installed
    if ! command -v postfix &> /dev/null; then
        print_error "Postfix is not installed"
        return
    fi
    
    # Check main.cf file
    if [[ ! -f /etc/postfix/main.cf ]]; then
        print_error "Postfix main.cf not found"
        return
    fi
    
    # Validate syntax
    if postfix check &> /dev/null; then
        print_status "Postfix configuration syntax is valid"
    else
        print_error "Postfix configuration syntax errors found"
        postfix check 2>&1 | tee -a "$VALIDATION_LOG"
    fi
    
    # Check critical parameters
    local required_params=("myhostname" "mydomain" "myorigin" "inet_interfaces")
    
    for param in "${required_params[@]}"; do
        if grep -q "^${param}" /etc/postfix/main.cf; then
            value=$(grep "^${param}" /etc/postfix/main.cf | cut -d= -f2 | tr -d ' ')
            print_status "${param}: ${value}"
        else
            print_error "Required parameter ${param} not found"
        fi
    done
    
    # Check virtual domains configuration
    if [[ -f /etc/postfix/mysql-virtual-mailbox-domains.cf ]]; then
        print_status "Virtual domains configuration found"
        
        # Check MySQL connection parameters
        if grep -q "user.*mailuser" /etc/postfix/mysql-virtual-mailbox-domains.cf; then
            print_status "MySQL user configured correctly"
        else
            print_warning "MySQL user may not be configured correctly"
        fi
    else
        print_warning "Virtual domains configuration not found"
    fi
    
    # Check TLS configuration
    if grep -q "^smtpd_tls_cert_file" /etc/postfix/main.cf; then
        cert_file=$(grep "^smtpd_tls_cert_file" /etc/postfix/main.cf | cut -d= -f2 | tr -d ' ')
        if [[ -f "$cert_file" ]]; then
            print_status "TLS certificate file exists: $cert_file"
        else
            print_error "TLS certificate file not found: $cert_file"
        fi
    else
        print_warning "TLS configuration not found"
    fi
    
    # Check service status
    if systemctl is-active --quiet postfix; then
        print_status "Postfix service is running"
    else
        print_error "Postfix service is not running"
    fi
}

# Function to validate Dovecot configuration
validate_dovecot() {
    print_header "Validating Dovecot Configuration"
    
    # Check if Dovecot is installed
    if ! command -v dovecot &> /dev/null; then
        print_error "Dovecot is not installed"
        return
    fi
    
    # Check dovecot.conf file
    if [[ ! -f /etc/dovecot/dovecot.conf ]]; then
        print_error "Dovecot configuration file not found"
        return
    fi
    
    # Validate configuration
    if doveconf -n &> /dev/null; then
        print_status "Dovecot configuration is valid"
    else
        print_error "Dovecot configuration errors found"
        doveconf -n 2>&1 | tee -a "$VALIDATION_LOG"
    fi
    
    # Check critical settings
    local protocols=$(doveconf -n protocols 2>/dev/null | cut -d= -f2 | tr -d ' ')
    if [[ -n "$protocols" ]]; then
        print_status "Protocols: $protocols"
    else
        print_warning "No protocols configured"
    fi
    
    # Check mail location
    local mail_location=$(doveconf -n mail_location 2>/dev/null | cut -d= -f2 | tr -d ' ')
    if [[ -n "$mail_location" ]]; then
        print_status "Mail location: $mail_location"
        
        # Check if mail directory exists
        if [[ "$mail_location" =~ maildir:/(.*) ]]; then
            mail_dir="${BASH_REMATCH[1]}"
            if [[ -d "$mail_dir" ]]; then
                print_status "Mail directory exists: $mail_dir"
            else
                print_warning "Mail directory not found: $mail_dir"
            fi
        fi
    else
        print_warning "Mail location not configured"
    fi
    
    # Check authentication
    if doveconf -n passdb 2>/dev/null | grep -q "driver.*sql"; then
        print_status "SQL authentication configured"
        
        # Check SQL configuration file
        local sql_file=$(doveconf -n passdb 2>/dev/null | grep "args" | cut -d= -f2 | tr -d ' ')
        if [[ -f "$sql_file" ]]; then
            print_status "SQL configuration file exists: $sql_file"
            
            # Check database connection
            if grep -q "connect.*host=localhost" "$sql_file"; then
                print_status "Database connection configured"
            else
                print_warning "Database connection may not be configured correctly"
            fi
        else
            print_error "SQL configuration file not found: $sql_file"
        fi
    else
        print_warning "SQL authentication not configured"
    fi
    
    # Check SSL configuration
    if doveconf -n ssl 2>/dev/null | grep -q "ssl.*required"; then
        print_status "SSL is required"
        
        local ssl_cert=$(doveconf -n ssl_cert 2>/dev/null | cut -d= -f2 | tr -d ' ')
        local ssl_key=$(doveconf -n ssl_key 2>/dev/null | cut -d= -f2 | tr -d ' ')
        
        if [[ -f "$ssl_cert" ]]; then
            print_status "SSL certificate exists: $ssl_cert"
        else
            print_error "SSL certificate not found: $ssl_cert"
        fi
        
        if [[ -f "$ssl_key" ]]; then
            print_status "SSL key exists: $ssl_key"
        else
            print_error "SSL key not found: $ssl_key"
        fi
    else
        print_warning "SSL not configured"
    fi
    
    # Check service status
    if systemctl is-active --quiet dovecot; then
        print_status "Dovecot service is running"
    else
        print_error "Dovecot service is not running"
    fi
}

# Function to validate database configuration
validate_database() {
    print_header "Validating Database Configuration"
    
    # Check if MySQL/MariaDB is installed
    if ! command -v mysql &> /dev/null; then
        print_error "MySQL/MariaDB is not installed"
        return
    fi
    
    # Check service status
    if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
        print_status "Database service is running"
    else
        print_error "Database service is not running"
        return
    fi
    
    # Test root connection
    if mysql -u root -e "SELECT 1;" &> /dev/null; then
        print_status "Root database connection successful"
    else
        print_error "Cannot connect to database as root"
        return
    fi
    
    # Check mailserver database
    if mysql -u root -e "USE mailserver;" &> /dev/null; then
        print_status "Mailserver database exists"
        
        # Check tables
        local tables=$(mysql -u root -e "USE mailserver; SHOW TABLES;" 2>/dev/null | wc -l)
        if [[ $tables -ge 3 ]]; then
            print_status "Found $tables tables in mailserver database"
            
            # Check required tables
            local required_tables=("domains" "users" "aliases")
            for table in "${required_tables[@]}"; do
                if mysql -u root -e "USE mailserver; DESCRIBE $table;" &> /dev/null; then
                    print_status "Table $table exists"
                else
                    print_error "Required table $table not found"
                fi
            done
        else
            print_warning "Insufficient tables in mailserver database"
        fi
        
        # Check data
        local domain_count=$(mysql -u root -e "USE mailserver; SELECT COUNT(*) FROM domains;" 2>/dev/null | tail -n1)
        if [[ $domain_count -gt 0 ]]; then
            print_status "Found $domain_count domain(s) configured"
        else
            print_warning "No domains configured in database"
        fi
        
        local user_count=$(mysql -u root -e "USE mailserver; SELECT COUNT(*) FROM users;" 2>/dev/null | tail -n1)
        if [[ $user_count -gt 0 ]]; then
            print_status "Found $user_count user(s) configured"
        else
            print_warning "No users configured in database"
        fi
    else
        print_error "Mailserver database does not exist"
    fi
    
    # Check mailuser
    if mysql -u root -e "SELECT User FROM mysql.user WHERE User='mailuser';" 2>/dev/null | grep -q mailuser; then
        print_status "Mailuser exists"
        
        # Test mailuser connection
        if mysql -u mailuser -e "SELECT 1;" &> /dev/null; then
            print_status "Mailuser connection successful"
        else
            print_warning "Mailuser connection failed"
        fi
    else
        print_error "Mailuser does not exist"
    fi
}

# Function to validate SSL certificates
validate_ssl() {
    print_header "Validating SSL Certificates"
    
    local cert_file="/etc/ssl/certs/mailserver.crt"
    local key_file="/etc/ssl/private/mailserver.key"
    
    # Check certificate file
    if [[ -f "$cert_file" ]]; then
        print_status "SSL certificate file exists: $cert_file"
        
        # Check certificate validity
        if openssl x509 -in "$cert_file" -noout -checkend 86400 &> /dev/null; then
            expiry=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
            print_status "Certificate is valid until: $expiry"
        else
            print_error "Certificate has expired or is invalid"
        fi
        
        # Check certificate details
        local subject=$(openssl x509 -in "$cert_file" -noout -subject | cut -d= -f2)
        print_status "Certificate subject: $subject"
        
        local issuer=$(openssl x509 -in "$cert_file" -noout -issuer | cut -d= -f2)
        print_status "Certificate issuer: $issuer"
    else
        print_error "SSL certificate file not found: $cert_file"
    fi
    
    # Check key file
    if [[ -f "$key_file" ]]; then
        print_status "SSL key file exists: $key_file"
        
        # Check key permissions
        local permissions=$(stat -c "%a" "$key_file")
        if [[ "$permissions" == "600" ]]; then
            print_status "SSL key file has correct permissions (600)"
        else
            print_warning "SSL key file has insecure permissions ($permissions)"
        fi
    else
        print_error "SSL key file not found: $key_file"
    fi
    
    # Check certificate and key match
    if [[ -f "$cert_file" && -f "$key_file" ]]; then
        cert_md5=$(openssl x509 -noout -modulus -in "$cert_file" | openssl md5)
        key_md5=$(openssl rsa -noout -modulus -in "$key_file" | openssl md5)
        
        if [[ "$cert_md5" == "$key_md5" ]]; then
            print_status "Certificate and key match"
        else
            print_error "Certificate and key do not match"
        fi
    fi
}

# Function to validate mail directories
validate_directories() {
    print_header "Validating Mail Directories"
    
    local directories=("/var/vmail" "/var/spool/postfix" "/etc/postfix" "/etc/dovecot")
    
    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            print_status "Directory exists: $dir"
            
            # Check permissions
            local owner=$(stat -c "%U:%G" "$dir")
            print_status "Owner: $owner"
            
            # Check disk space
            local usage=$(df -h "$dir" | awk 'NR==2 {print $5}')
            print_status "Disk usage: $usage"
        else
            print_error "Directory not found: $dir"
        fi
    done
    
    # Check vmail user
    if id vmail &> /dev/null; then
        print_status "Vmail user exists"
        
        # Check vmail user groups
        local groups=$(id vmail | cut -d= -f2)
        print_status "Vmail user groups: $groups"
    else
        print_warning "Vmail user does not exist"
    fi
}

# Function to validate firewall configuration
validate_firewall() {
    print_header "Validating Firewall Configuration"
    
    # Check UFW (Ubuntu/Debian)
    if command -v ufw &> /dev/null; then
        print_status "UFW firewall detected"
        
        # Check if UFW is active
        if ufw status | grep -q "Status: active"; then
            print_status "UFW is active"
            
            # Check mail ports
            local mail_ports=("25" "587" "143" "993" "110" "995")
            for port in "${mail_ports[@]}"; do
                if ufw status | grep -q "$port.*ALLOW"; then
                    print_status "Port $port is allowed"
                else
                    print_warning "Port $port may not be allowed"
                fi
            done
        else
            print_warning "UFW is not active"
        fi
    fi
    
    # Check firewalld (CentOS/RHEL)
    if command -v firewall-cmd &> /dev/null; then
        print_status "Firewalld detected"
        
        # Check if firewalld is running
        if systemctl is-active --quiet firewalld; then
            print_status "Firewalld is running"
            
            # Check mail services
            local mail_services=("smtp" "smtps" "imap" "imaps" "pop3" "pop3s")
            for service in "${mail_services[@]}"; do
                if firewall-cmd --list-services | grep -q "$service"; then
                    print_status "Service $service is allowed"
                else
                    print_warning "Service $service may not be allowed"
                fi
            done
        else
            print_warning "Firewalld is not running"
        fi
    fi
    
    # Check iptables directly
    if command -v iptables &> /dev/null; then
        local rules=$(iptables -L | wc -l)
        if [[ $rules -gt 10 ]]; then
            print_status "iptables has $rules rules configured"
        else
            print_warning "iptables may not be configured"
        fi
    fi
}

# Function to validate DNS configuration
validate_dns() {
    print_header "Validating DNS Configuration"
    
    # Get domain from Postfix configuration
    if [[ -f /etc/postfix/main.cf ]]; then
        local domain=$(grep "^mydomain" /etc/postfix/main.cf | cut -d= -f2 | tr -d ' ')
        
        if [[ -n "$domain" ]]; then
            print_status "Detected domain: $domain"
            
            # Check MX record
            if dig +short MX "$domain" &> /dev/null; then
                local mx_record=$(dig +short MX "$domain" | head -n1)
                print_status "MX record found: $mx_record"
                
                # Check if MX points to this server
                local server_ip=$(hostname -I | awk '{print $1}')
                local mx_ip=$(dig +short $(echo "$mx_record" | awk '{print $2}') | head -n1)
                
                if [[ "$server_ip" == "$mx_ip" ]]; then
                    print_status "MX record points to this server"
                else
                    print_warning "MX record does not point to this server (Server: $server_ip, MX: $mx_ip)"
                fi
            else
                print_warning "No MX record found for $domain"
            fi
            
            # Check A record
            if dig +short "$domain" &> /dev/null; then
                local a_record=$(dig +short "$domain" | head -n1)
                print_status "A record found: $a_record"
            else
                print_warning "No A record found for $domain"
            fi
            
            # Check SPF record
            if dig +short TXT "$domain" | grep -q "v=spf1"; then
                local spf_record=$(dig +short TXT "$domain" | grep "v=spf1")
                print_status "SPF record found: $spf_record"
            else
                print_warning "No SPF record found for $domain"
            fi
            
            # Check DKIM record
            if dig +short TXT "mail._domainkey.$domain" &> /dev/null; then
                local dkim_record=$(dig +short TXT "mail._domainkey.$domain")
                print_status "DKIM record found: $dkim_record"
            else
                print_warning "No DKIM record found for $domain"
            fi
        else
            print_warning "Could not detect domain from Postfix configuration"
        fi
    else
        print_warning "Postfix configuration not found for DNS validation"
    fi
}

# Function to validate system resources
validate_system_resources() {
    print_header "Validating System Resources"
    
    # Check memory usage
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [[ $mem_usage -lt 80 ]]; then
        print_status "Memory usage: ${mem_usage}%"
    else
        print_warning "High memory usage: ${mem_usage}%"
    fi
    
    # Check disk usage
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -lt 80 ]]; then
        print_status "Disk usage: ${disk_usage}%"
    else
        print_warning "High disk usage: ${disk_usage}%"
    fi
    
    # Check load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | tr -d ' ')
    local cpu_count=$(nproc)
    if (( $(echo "$load_avg < $cpu_count" | bc -l) )); then
        print_status "Load average: $load_avg (CPU cores: $cpu_count)"
    else
        print_warning "High load average: $load_avg (CPU cores: $cpu_count)"
    fi
    
    # Check swap usage
    local swap_usage=$(free | awk 'NR==3{if($2>0) printf "%.0f", $3*100/$2; else print "0"}')
    if [[ $swap_usage -lt 50 ]]; then
        print_status "Swap usage: ${swap_usage}%"
    else
        print_warning "High swap usage: ${swap_usage}%"
    fi
}

# Function to generate validation report
generate_report() {
    print_header "Validation Summary"
    
    echo "Issues Found: $ISSUES_FOUND" | tee -a "$VALIDATION_LOG"
    echo "Warnings: $WARNINGS_FOUND" | tee -a "$VALIDATION_LOG"
    echo "Critical Errors: $CRITICAL_ERRORS" | tee -a "$VALIDATION_LOG"
    echo
    
    if [[ $CRITICAL_ERRORS -gt 0 ]]; then
        echo -e "${RED}Status: CRITICAL ERRORS FOUND${NC}" | tee -a "$VALIDATION_LOG"
        echo "Please address critical errors before proceeding." | tee -a "$VALIDATION_LOG"
    elif [[ $WARNINGS_FOUND -gt 0 ]]; then
        echo -e "${YELLOW}Status: WARNINGS FOUND${NC}" | tee -a "$VALIDATION_LOG"
        echo "Configuration is functional but may need attention." | tee -a "$VALIDATION_LOG"
    else
        echo -e "${GREEN}Status: VALID${NC}" | tee -a "$VALIDATION_LOG"
        echo "Configuration appears to be valid." | tee -a "$VALIDATION_LOG"
    fi
    
    echo
    echo "Detailed validation log saved to: $VALIDATION_LOG" | tee -a "$VALIDATION_LOG"
    
    # Show recommendations
    if [[ $CRITICAL_ERRORS -gt 0 || $WARNINGS_FOUND -gt 0 ]]; then
        echo
        echo "Recommendations:" | tee -a "$VALIDATION_LOG"
        echo "1. Fix all critical errors immediately" | tee -a "$VALIDATION_LOG"
        echo "2. Review warnings and address if necessary" | tee -a "$VALIDATION_LOG"
        echo "3. Run validation again after making changes" | tee -a "$VALIDATION_LOG"
        echo "4. Consider setting up monitoring for ongoing validation" | tee -a "$VALIDATION_LOG"
    fi
}

# Function to show usage
show_usage() {
    echo "LibTMail Configuration Validation Tool"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -q, --quick    Quick validation (basic checks only)"
    echo "  -v, --verbose  Verbose output"
    echo "  --postfix      Validate Postfix only"
    echo "  --dovecot      Validate Dovecot only"
    echo "  --database     Validate database only"
    echo "  --ssl          Validate SSL only"
    echo "  --dns          Validate DNS only"
    echo "  --system       Validate system resources only"
    echo
}

# Main function
main() {
    local validation_type="all"
    local quick_validation=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -q|--quick)
                quick_validation=true
                shift
                ;;
            -v|--verbose)
                set -x
                shift
                ;;
            --postfix)
                validation_type="postfix"
                shift
                ;;
            --dovecot)
                validation_type="dovecot"
                shift
                ;;
            --database)
                validation_type="database"
                shift
                ;;
            --ssl)
                validation_type="ssl"
                shift
                ;;
            --dns)
                validation_type="dns"
                shift
                ;;
            --system)
                validation_type="system"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    check_root
    init_validation
    
    case $validation_type in
        "postfix")
            validate_postfix
            ;;
        "dovecot")
            validate_dovecot
            ;;
        "database")
            validate_database
            ;;
        "ssl")
            validate_ssl
            ;;
        "dns")
            validate_dns
            ;;
        "system")
            validate_system_resources
            ;;
        "all")
            if [[ $quick_validation == true ]]; then
                validate_postfix
                validate_dovecot
                validate_database
                validate_ssl
            else
                validate_postfix
                validate_dovecot
                validate_database
                validate_ssl
                validate_directories
                validate_firewall
                validate_dns
                validate_system_resources
            fi
            ;;
    esac
    
    generate_report
    
    if [[ $CRITICAL_ERRORS -gt 0 ]]; then
        exit 2
    elif [[ $WARNINGS_FOUND -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"
