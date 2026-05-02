#!/bin/bash

# LibTMail Automated Testing Script
# Comprehensive testing of mail server installation and functionality
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
TEST_LOG="/tmp/libtmail_test.log"
TEST_RESULTS=()
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$TEST_LOG"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$TEST_LOG"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$TEST_LOG"
}

print_header() {
    echo -e "${BLUE}================================${NC}" | tee -a "$TEST_LOG"
    echo -e "${BLUE}$1${NC}" | tee -a "$TEST_LOG"
    echo -e "${BLUE}================================${NC}" | tee -a "$TEST_LOG"
}

# Function to add test result
add_test_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    case $result in
        "PASS")
            PASSED_TESTS=$((PASSED_TESTS + 1))
            echo -e "${GREEN}[PASS]${NC} $test_name: $message" | tee -a "$TEST_LOG"
            ;;
        "FAIL")
            FAILED_TESTS=$((FAILED_TESTS + 1))
            echo -e "${RED}[FAIL]${NC} $test_name: $message" | tee -a "$TEST_LOG"
            ;;
        "WARN")
            WARNING_TESTS=$((WARNING_TESTS + 1))
            echo -e "${YELLOW}[WARN]${NC} $test_name: $message" | tee -a "$TEST_LOG"
            ;;
    esac
    
    TEST_RESULTS+=("$test_name|$result|$message")
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to initialize test environment
init_test_env() {
    print_header "Initializing Test Environment"
    
    # Clear previous log
    > "$TEST_LOG"
    
    # Test date and time
    echo "LibTMail Automated Test Report" | tee -a "$TEST_LOG"
    echo "Date: $(date)" | tee -a "$TEST_LOG"
    echo "Hostname: $(hostname)" | tee -a "$TEST_LOG"
    echo "OS: $(uname -a)" | tee -a "$TEST_LOG"
    echo "================================" | tee -a "$TEST_LOG"
    
    print_status "Test environment initialized"
}

# Function to test system requirements
test_system_requirements() {
    print_header "Testing System Requirements"
    
    # Test OS
    if [[ -f /etc/os-release ]]; then
        add_test_result "OS Detection" "PASS" "$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    else
        add_test_result "OS Detection" "FAIL" "Cannot detect operating system"
    fi
    
    # Test architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        add_test_result "Architecture" "PASS" "$ARCH"
    else
        add_test_result "Architecture" "WARN" "$ARCH (x86_64 recommended)"
    fi
    
    # Test RAM
    RAM=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    if [[ $RAM -ge 2 ]]; then
        add_test_result "Memory" "PASS" "${RAM}GB"
    else
        add_test_result "Memory" "WARN" "${RAM}GB (2GB+ recommended)"
    fi
    
    # Test disk space
    DISK=$(df / | awk 'NR==2 {print $4}')
    DISK_GB=$((DISK / 1024 / 1024))
    if [[ $DISK_GB -ge 20 ]]; then
        add_test_result "Disk Space" "PASS" "${DISK_GB}GB"
    else
        add_test_result "Disk Space" "WARN" "${DISK_GB}GB (20GB+ recommended)"
    fi
    
    # Test internet connection
    if ping -c 1 google.com &> /dev/null; then
        add_test_result "Internet Connection" "PASS" "Connected"
    else
        add_test_result "Internet Connection" "FAIL" "No internet connection"
    fi
}

# Function to test package installations
test_package_installations() {
    print_header "Testing Package Installations"
    
    # Test Postfix
    if command -v postfix &> /dev/null; then
        POSTFIX_VERSION=$(postfix -d mail_version 2>/dev/null | grep "mail_version" | cut -d= -f2 | tr -d ' ')
        add_test_result "Postfix" "PASS" "Version: $POSTFIX_VERSION"
    else
        add_test_result "Postfix" "FAIL" "Postfix not installed"
    fi
    
    # Test Dovecot
    if command -v dovecot &> /dev/null; then
        DOVECOT_VERSION=$(dovecot --version 2>/dev/null)
        add_test_result "Dovecot" "PASS" "Version: $DOVECOT_VERSION"
    else
        add_test_result "Dovecot" "FAIL" "Dovecot not installed"
    fi
    
    # Test MariaDB/MySQL
    if command -v mysql &> /dev/null; then
        MYSQL_VERSION=$(mysql --version 2>/dev/null | cut -d' ' -f2 | cut -d',' -f1)
        add_test_result "MySQL/MariaDB" "PASS" "Version: $MYSQL_VERSION"
    else
        add_test_result "MySQL/MariaDB" "FAIL" "MySQL/MariaDB not installed"
    fi
    
    # Test SpamAssassin
    if command -v spamassassin &> /dev/null; then
        SPAM_VERSION=$(spamassassin --version 2>/dev/null | cut -d' ' -f3)
        add_test_result "SpamAssassin" "PASS" "Version: $SPAM_VERSION"
    else
        add_test_result "SpamAssassin" "WARN" "SpamAssassin not installed"
    fi
    
    # Test ClamAV
    if command -v clamscan &> /dev/null; then
        CLAM_VERSION=$(clamscan --version 2>/dev/null | head -n1 | cut -d' ' -f2)
        add_test_result "ClamAV" "PASS" "Version: $CLAM_VERSION"
    else
        add_test_result "ClamAV" "WARN" "ClamAV not installed"
    fi
    
    # Test OpenDKIM
    if command -v opendkim &> /dev/null; then
        Opendkim_VERSION=$(opendkim -V 2>/dev/null | head -n1 | cut -d' ' -f3)
        add_test_result "OpenDKIM" "PASS" "Version: $Opendkim_VERSION"
    else
        add_test_result "OpenDKIM" "WARN" "OpenDKIM not installed"
    fi
}

# Function to test service status
test_service_status() {
    print_header "Testing Service Status"
    
    # Test Postfix
    if systemctl is-active --quiet postfix; then
        add_test_result "Postfix Service" "PASS" "Running"
    else
        add_test_result "Postfix Service" "FAIL" "Not running"
    fi
    
    # Test Dovecot
    if systemctl is-active --quiet dovecot; then
        add_test_result "Dovecot Service" "PASS" "Running"
    else
        add_test_result "Dovecot Service" "FAIL" "Not running"
    fi
    
    # Test MariaDB
    if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
        add_test_result "MariaDB Service" "PASS" "Running"
    else
        add_test_result "MariaDB Service" "FAIL" "Not running"
    fi
    
    # Test SpamAssassin
    if systemctl is-active --quiet spamassassin; then
        add_test_result "SpamAssassin Service" "PASS" "Running"
    else
        add_test_result "SpamAssassin Service" "WARN" "Not running"
    fi
    
    # Test ClamAV
    if systemctl is-active --quiet clamav-daemon; then
        add_test_result "ClamAV Service" "PASS" "Running"
    else
        add_test_result "ClamAV Service" "WARN" "Not running"
    fi
    
    # Test OpenDKIM
    if systemctl is-active --quiet opendkim; then
        add_test_result "OpenDKIM Service" "PASS" "Running"
    else
        add_test_result "OpenDKIM Service" "WARN" "Not running"
    fi
}

# Function to test port availability
test_port_availability() {
    print_header "Testing Port Availability"
    
    local ports=("25:SMTP" "587:SMTPS" "143:IMAP" "993:IMAPS" "110:POP3" "995:POP3S" "80:HTTP" "443:HTTPS")
    
    for port_info in "${ports[@]}"; do
        local port=$(echo "$port_info" | cut -d: -f1)
        local service=$(echo "$port_info" | cut -d: -f2)
        
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            add_test_result "Port $port ($service)" "PASS" "Open"
        else
            add_test_result "Port $port ($service)" "FAIL" "Closed"
        fi
    done
}

# Function to test database connectivity
test_database_connectivity() {
    print_header "Testing Database Connectivity"
    
    # Test MySQL connection
    if mysql -u root -e "SELECT 1;" &> /dev/null; then
        add_test_result "MySQL Root Connection" "PASS" "Connected"
    else
        add_test_result "MySQL Root Connection" "FAIL" "Cannot connect"
    fi
    
    # Test mailserver database
    if mysql -u root -e "USE mailserver; SHOW TABLES;" &> /dev/null; then
        TABLE_COUNT=$(mysql -u root -e "USE mailserver; SHOW TABLES;" | wc -l)
        add_test_result "Mailserver Database" "PASS" "$TABLE_COUNT tables found"
    else
        add_test_result "Mailserver Database" "FAIL" "Database not found"
    fi
    
    # Test mailuser
    if mysql -u mailuser -e "SELECT 1;" &> /dev/null; then
        add_test_result "Mailuser Connection" "PASS" "Connected"
    else
        add_test_result "Mailuser Connection" "FAIL" "Cannot connect"
    fi
}

# Function to test SSL certificates
test_ssl_certificates() {
    print_header "Testing SSL Certificates"
    
    local cert_file="/etc/ssl/certs/mailserver.crt"
    local key_file="/etc/ssl/private/mailserver.key"
    
    # Test certificate file
    if [[ -f "$cert_file" ]]; then
        if openssl x509 -in "$cert_file" -noout -checkend 86400 &> /dev/null; then
            EXPIRY=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
            add_test_result "SSL Certificate" "PASS" "Valid until $EXPIRY"
        else
            add_test_result "SSL Certificate" "WARN" "Expired or invalid"
        fi
    else
        add_test_result "SSL Certificate" "FAIL" "Certificate file not found"
    fi
    
    # Test key file
    if [[ -f "$key_file" ]]; then
        add_test_result "SSL Key" "PASS" "Key file exists"
    else
        add_test_result "SSL Key" "FAIL" "Key file not found"
    fi
    
    # Test certificate and key match
    if [[ -f "$cert_file" && -f "$key_file" ]]; then
        cert_md5=$(openssl x509 -noout -modulus -in "$cert_file" | openssl md5)
        key_md5=$(openssl rsa -noout -modulus -in "$key_file" | openssl md5)
        
        if [[ "$cert_md5" == "$key_md5" ]]; then
            add_test_result "SSL Certificate-Key Match" "PASS" "Certificates match"
        else
            add_test_result "SSL Certificate-Key Match" "FAIL" "Certificates do not match"
        fi
    fi
}

# Function to test mail directories
test_mail_directories() {
    print_header "Testing Mail Directories"
    
    local directories=("/var/vmail" "/var/spool/postfix" "/etc/postfix" "/etc/dovecot")
    
    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            add_test_result "Directory $dir" "PASS" "Exists"
        else
            add_test_result "Directory $dir" "FAIL" "Not found"
        fi
    done
    
    # Test vmail permissions
    if [[ -d "/var/vmail" ]]; then
        owner=$(stat -c "%U:%G" /var/vmail)
        if [[ "$owner" == "vmail:mail" ]]; then
            add_test_result "Vmail Permissions" "PASS" "$owner"
        else
            add_test_result "Vmail Permissions" "WARN" "$owner (expected: vmail:mail)"
        fi
    fi
}

# Function to test configuration files
test_configuration_files() {
    print_header "Testing Configuration Files"
    
    local configs=(
        "/etc/postfix/main.cf"
        "/etc/dovecot/dovecot.conf"
        "/etc/spamassassin/local.cf"
        "/etc/clamav/clamd.conf"
        "/etc/opendkim.conf"
    )
    
    for config in "${configs[@]}"; do
        if [[ -f "$config" ]]; then
            add_test_result "Config $(basename "$config")" "PASS" "Exists"
        else
            add_test_result "Config $(basename "$config")" "WARN" "Not found"
        fi
    done
}

# Function to test mail functionality
test_mail_functionality() {
    print_header "Testing Mail Functionality"
    
    # Test Postfix configuration
    if postfix check &> /dev/null; then
        add_test_result "Postfix Configuration" "PASS" "Valid"
    else
        add_test_result "Postfix Configuration" "FAIL" "Invalid"
    fi
    
    # Test Dovecot configuration
    if doveconf -n &> /dev/null; then
        add_test_result "Dovecot Configuration" "PASS" "Valid"
    else
        add_test_result "Dovecot Configuration" "FAIL" "Invalid"
    fi
    
    # Test mail queue
    queue_size=$(mailq | grep -c '^[A-F0-9]' 2>/dev/null || echo "0")
    if [[ $queue_size -lt 100 ]]; then
        add_test_result "Mail Queue" "PASS" "$queue_size messages"
    else
        add_test_result "Mail Queue" "WARN" "$queue_size messages (high)"
    fi
}

# Function to test management scripts
test_management_scripts() {
    print_header "Testing Management Scripts"
    
    local scripts=(
        "/usr/local/bin/mailadmin"
        "/usr/local/bin/mailbackup"
        "/usr/local/bin/mailmonitor"
        "/usr/local/bin/mailqueue"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" && -x "$script" ]]; then
            add_test_result "Script $(basename "$script")" "PASS" "Exists and executable"
        else
            add_test_result "Script $(basename "$script")" "WARN" "Not found or not executable"
        fi
    done
}

# Function to test webmail (if installed)
test_webmail() {
    print_header "Testing Webmail"
    
    if [[ -d "/var/www/html/webmail" ]]; then
        add_test_result "Webmail Directory" "PASS" "Exists"
        
        # Test Apache/Nginx
        if systemctl is-active --quiet apache2 || systemctl is-active --quiet nginx; then
            add_test_result "Web Server" "PASS" "Running"
        else
            add_test_result "Web Server" "WARN" "Not running"
        fi
    else
        add_test_result "Webmail" "WARN" "Not installed"
    fi
}

# Function to test DNS resolution
test_dns_resolution() {
    print_header "Testing DNS Resolution"
    
    # Get domain from configuration
    if [[ -f "/etc/postfix/main.cf" ]]; then
        domain=$(grep "^mydomain" /etc/postfix/main.cf | cut -d= -f2 | tr -d ' ')
        
        if [[ -n "$domain" ]]; then
            # Test MX record
            if dig +short MX "$domain" &> /dev/null; then
                mx_record=$(dig +short MX "$domain" | head -n1)
                add_test_result "MX Record for $domain" "PASS" "$mx_record"
            else
                add_test_result "MX Record for $domain" "WARN" "No MX record found"
            fi
            
            # Test A record
            if dig +short "$domain" &> /dev/null; then
                a_record=$(dig +short "$domain" | head -n1)
                add_test_result "A Record for $domain" "PASS" "$a_record"
            else
                add_test_result "A Record for $domain" "WARN" "No A record found"
            fi
        else
            add_test_result "Domain Detection" "WARN" "Could not detect domain"
        fi
    else
        add_test_result "Domain Detection" "WARN" "Postfix config not found"
    fi
}

# Function to generate test report
generate_test_report() {
    print_header "Test Report Summary"
    
    echo "Total Tests: $TOTAL_TESTS" | tee -a "$TEST_LOG"
    echo "Passed: $PASSED_TESTS" | tee -a "$TEST_LOG"
    echo "Failed: $FAILED_TESTS" | tee -a "$TEST_LOG"
    echo "Warnings: $WARNING_TESTS" | tee -a "$TEST_LOG"
    echo
    
    # Calculate success rate
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo "Success Rate: ${success_rate}%" | tee -a "$TEST_LOG"
        
        if [[ $success_rate -ge 90 ]]; then
            echo -e "${GREEN}Overall Status: EXCELLENT${NC}" | tee -a "$TEST_LOG"
        elif [[ $success_rate -ge 75 ]]; then
            echo -e "${YELLOW}Overall Status: GOOD${NC}" | tee -a "$TEST_LOG"
        elif [[ $success_rate -ge 50 ]]; then
            echo -e "${YELLOW}Overall Status: FAIR${NC}" | tee -a "$TEST_LOG"
        else
            echo -e "${RED}Overall Status: POOR${NC}" | tee -a "$TEST_LOG"
        fi
    fi
    
    echo
    echo "Detailed log saved to: $TEST_LOG" | tee -a "$TEST_LOG"
    
    # Show failed tests
    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo
        echo "Failed Tests:" | tee -a "$TEST_LOG"
        for result in "${TEST_RESULTS[@]}"; do
            if [[ $(echo "$result" | cut -d'|' -f2) == "FAIL" ]]; then
                test_name=$(echo "$result" | cut -d'|' -f1)
                message=$(echo "$result" | cut -d'|' -f3)
                echo "  - $test_name: $message" | tee -a "$TEST_LOG"
            fi
        done
    fi
}

# Function to run all tests
run_all_tests() {
    print_header "Starting LibTMail Automated Tests"
    
    init_test_env
    test_system_requirements
    test_package_installations
    test_service_status
    test_port_availability
    test_database_connectivity
    test_ssl_certificates
    test_mail_directories
    test_configuration_files
    test_mail_functionality
    test_management_scripts
    test_webmail
    test_dns_resolution
    generate_test_report
}

# Function to show usage
show_usage() {
    echo "LibTMail Automated Testing Script"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -q, --quick    Run quick tests only"
    echo "  -v, --verbose  Verbose output"
    echo "  -r, --report   Generate HTML report"
    echo "  --system       Test system requirements only"
    echo "  --services     Test service status only"
    echo "  --network      Test network connectivity only"
    echo
}

# Main function
main() {
    local quick_test=false
    local verbose=false
    local html_report=false
    local test_type="all"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -q|--quick)
                quick_test=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -r|--report)
                html_report=true
                shift
                ;;
            --system)
                test_type="system"
                shift
                ;;
            --services)
                test_type="services"
                shift
                ;;
            --network)
                test_type="network"
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
    
    case $test_type in
        "system")
            init_test_env
            test_system_requirements
            test_package_installations
            ;;
        "services")
            init_test_env
            test_service_status
            ;;
        "network")
            init_test_env
            test_port_availability
            test_dns_resolution
            ;;
        "all")
            run_all_tests
            ;;
    esac
    
    if [[ $html_report == true ]]; then
        print_status "HTML report generation not implemented yet"
    fi
    
    if [[ $FAILED_TESTS -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"
