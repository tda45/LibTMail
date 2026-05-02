#!/bin/bash

# LibTMail Docker Management Script
# Easy Docker deployment and management
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
    echo "             |___/     Docker Edition     "
    echo -e "${NC}"
    echo -e "${GREEN}LibTMail - Docker Mail Server Management${NC}"
    echo -e "${YELLOW}Management Script v1.0${NC}"
    echo
}

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        print_status "Please install Docker first: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        print_status "Please install Docker Compose first: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    print_status "Docker and Docker Compose are available"
}

# Function to create environment file
create_env_file() {
    if [[ ! -f .env ]]; then
        print_header "Creating Environment File"
        
        echo "# LibTMail Docker Environment Configuration" > .env
        echo "# Generated on $(date)" >> .env
        echo >> .env
        
        # Get user input
        read -p "Enter your domain name (e.g., example.com): " domain
        read -p "Enter hostname (e.g., mail): " hostname
        read -p "Enter admin email address: " admin_email
        read -p "Enter timezone (e.g., UTC): " timezone
        
        # Set defaults if empty
        domain=${domain:-example.com}
        hostname=${hostname:-mail}
        admin_email=${admin_email:-admin@example.com}
        timezone=${timezone:-UTC}
        
        # Generate passwords
        mysql_root=$(openssl rand -base64 32)
        mysql_mail=$(openssl rand -base64 32)
        
        # Write to .env file
        echo "MAIL_DOMAIN=$domain" >> .env
        echo "MAIL_HOSTNAME=$hostname" >> .env
        echo "ADMIN_EMAIL=$admin_email" >> .env
        echo "MYSQL_ROOT_PASSWORD=$mysql_root" >> .env
        echo "MYSQL_MAIL_PASSWORD=$mysql_mail" >> .env
        echo "TZ=$timezone" >> .env
        
        print_status "Environment file created: .env"
        print_warning "MySQL Root Password: $mysql_root"
        print_warning "MySQL Mail Password: $mysql_mail"
        echo "Please save these passwords securely!"
        echo
    else
        print_status "Environment file already exists: .env"
    fi
}

# Function to start containers
start_containers() {
    print_header "Starting LibTMail Containers"
    
    if [[ ! -f .env ]]; then
        print_warning "Environment file not found, creating one..."
        create_env_file
    fi
    
    docker-compose up -d
    
    if [[ $? -eq 0 ]]; then
        print_status "Containers started successfully"
        show_status
    else
        print_error "Failed to start containers"
        exit 1
    fi
}

# Function to stop containers
stop_containers() {
    print_header "Stopping LibTMail Containers"
    
    docker-compose down
    
    print_status "Containers stopped"
}

# Function to restart containers
restart_containers() {
    print_header "Restarting LibTMail Containers"
    
    docker-compose restart
    
    print_status "Containers restarted"
    show_status
}

# Function to show container status
show_status() {
    print_header "Container Status"
    
    docker-compose ps
    
    echo
    print_status "Service URLs:"
    echo "  Webmail: http://localhost:80"
    echo "  HTTPS: https://localhost:443"
    echo "  phpMyAdmin: http://localhost:8080 (if enabled)"
    echo "  MailHog: http://localhost:8025 (if enabled)"
}

# Function to show logs
show_logs() {
    local service=$1
    
    if [[ -n "$service" ]]; then
        print_header "Logs for $service"
        docker-compose logs -f "$service"
    else
        print_header "All Logs"
        docker-compose logs -f
    fi
}

# Function to execute command in container
exec_command() {
    local service=$1
    shift
    
    if [[ -z "$service" ]]; then
        print_error "Service name is required"
        echo "Usage: $0 exec <service> <command>"
        echo "Available services: libtmail"
        exit 1
    fi
    
    print_header "Executing in $service"
    docker-compose exec "$service" "$@"
}

# Function to backup data
backup_data() {
    print_header "Backing Up Data"
    
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup volumes
    docker run --rm -v libtmail_mail_data:/data -v "$(pwd)/$backup_dir":/backup alpine tar czf /backup/mail_data.tar.gz -C /data .
    docker run --rm -v libtmail_mysql_data:/data -v "$(pwd)/$backup_dir":/backup alpine tar czf /backup/mysql_data.tar.gz -C /data .
    docker run --rm -v libtmail_ssl_certs:/data -v "$(pwd)/$backup_dir":/backup alpine tar czf /backup/ssl_certs.tar.gz -C /data .
    
    # Copy configuration files
    cp .env "$backup_dir/"
    cp docker-compose.yml "$backup_dir/"
    
    print_status "Backup completed: $backup_dir"
}

# Function to restore data
restore_data() {
    local backup_dir=$1
    
    if [[ -z "$backup_dir" ]]; then
        print_error "Backup directory is required"
        echo "Usage: $0 restore <backup_directory>"
        exit 1
    fi
    
    if [[ ! -d "$backup_dir" ]]; then
        print_error "Backup directory not found: $backup_dir"
        exit 1
    fi
    
    print_header "Restoring Data from $backup_dir"
    
    # Stop containers
    docker-compose down
    
    # Restore volumes
    docker run --rm -v libtmail_mail_data:/data -v "$(pwd)/$backup_dir":/backup alpine tar xzf /backup/mail_data.tar.gz -C /data
    docker run --rm -v libtmail_mysql_data:/data -v "$(pwd)/$backup_dir":/backup alpine tar xzf /backup/mysql_data.tar.gz -C /data
    docker run --rm -v libtmail_ssl_certs:/data -v "$(pwd)/$backup_dir":/backup alpine tar xzf /backup/ssl_certs.tar.gz -C /data
    
    # Restore configuration files
    cp "$backup_dir/.env" .
    cp "$backup_dir/docker-compose.yml" .
    
    # Start containers
    docker-compose up -d
    
    print_status "Data restored successfully"
}

# Function to update containers
update_containers() {
    print_header "Updating LibTMail Containers"
    
    # Pull latest images
    docker-compose pull
    
    # Rebuild and restart
    docker-compose up -d --build
    
    print_status "Containers updated"
    show_status
}

# Function to clean up
cleanup() {
    print_header "Cleaning Up Docker Resources"
    
    # Remove stopped containers
    docker-compose down --remove-orphans
    
    # Remove unused images
    docker image prune -f
    
    # Remove unused volumes (be careful!)
    read -p "Remove unused volumes? This may delete data! (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        docker volume prune -f
    fi
    
    print_status "Cleanup completed"
}

# Function to show usage
show_usage() {
    echo "LibTMail Docker Management Script"
    echo
    echo "Usage: $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  start           Start all containers"
    echo "  stop            Stop all containers"
    echo "  restart         Restart all containers"
    echo "  status          Show container status"
    echo "  logs [service]  Show logs (all or specific service)"
    echo "  exec <cmd>      Execute command in libtmail container"
    echo "  backup          Backup all data"
    echo "  restore <dir>   Restore data from backup"
    echo "  update          Update containers"
    echo "  cleanup         Clean up Docker resources"
    echo "  env             Create/update environment file"
    echo "  help            Show this help"
    echo
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs libtmail"
    echo "  $0 exec mailadmin list"
    echo "  $0 exec mysql -u root -p mailserver"
    echo "  $0 backup"
    echo "  $0 restore backups/20231201_120000"
    echo
}

# Main function
main() {
    local command=${1:-help}
    
    case $command in
        "start")
            check_docker
            create_env_file
            start_containers
            ;;
        "stop")
            check_docker
            stop_containers
            ;;
        "restart")
            check_docker
            restart_containers
            ;;
        "status")
            check_docker
            show_status
            ;;
        "logs")
            check_docker
            show_logs "$2"
            ;;
        "exec")
            check_docker
            exec_command "$@"
            ;;
        "backup")
            check_docker
            backup_data
            ;;
        "restore")
            check_docker
            restore_data "$2"
            ;;
        "update")
            check_docker
            update_containers
            ;;
        "cleanup")
            check_docker
            cleanup
            ;;
        "env")
            create_env_file
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
