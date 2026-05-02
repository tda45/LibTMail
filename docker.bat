@echo off
REM LibTMail Docker Management Script for Windows
REM Easy Docker deployment and management
REM Author: tda_45
REM Version: 1.0

setlocal enabledelayedexpansion

REM Colors for output
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

REM Function to print colored output
:print_status
echo %GREEN%[INFO]%NC% %~1
goto :eof

:print_warning
echo %YELLOW%[WARNING]%NC% %~1
goto :eof

:print_error
echo %RED%[ERROR]%NC% %~1
goto :eof

:print_header
echo %BLUE%================================%NC%
echo %BLUE%%~1%NC%
echo %BLUE%================================%NC%
goto :eof

REM Function to show banner
:show_banner
cls
echo %BLUE%
echo   _                 _            _     _   
echo  ^| ^|               ^| ^|          ^| ^|   ^| ^|  
echo  ^| ^|     ___   __ ^| ^|_ __ _ ___^| ^|_  ^| ^|  
echo  ^| ^|    / _ \ / _\` ^| __/ _\` / __^| __^| ^| ^|  
echo  ^| ^|___^| (_) ^| (_^| ^| ^|^| (_^| \__ \ ^|_^|  ^| ^|  
echo  ^|______\___/ \__, ^|\__\__,_^|___/\__^|_^|_^|  
echo               __/ ^|                      
echo              ^|___/     Docker Edition       
echo %NC%
echo %GREEN%LibTMail - Docker Mail Server Management%NC%
echo %YELLOW%Management Script v1.0%NC%
echo.
goto :eof

REM Function to check if Docker is installed
:check_docker
where docker >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "Docker is not installed"
    call :print_status "Please install Docker Desktop first: https://www.docker.com/products/docker-desktop"
    pause
    exit /b 1
)

where docker-compose >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "Docker Compose is not installed"
    call :print_status "Please install Docker Compose first"
    pause
    exit /b 1
)

call :print_status "Docker and Docker Compose are available"
goto :eof

REM Function to create environment file
:create_env_file
if not exist .env (
    call :print_header "Creating Environment File"
    
    echo # LibTMail Docker Environment Configuration > .env
    echo # Generated on %date% %time% >> .env
    echo. >> .env
    
    REM Get user input
    set /p "domain=Enter your domain name (e.g., example.com): "
    set /p "hostname=Enter hostname (e.g., mail): "
    set /p "admin_email=Enter admin email address: "
    set /p "timezone=Enter timezone (e.g., UTC): "
    
    REM Set defaults if empty
    if "%domain%"=="" set "domain=example.com"
    if "%hostname%"=="" set "hostname=mail"
    if "%admin_email%"=="" set "admin_email=admin@example.com"
    if "%timezone%"=="" set "timezone=UTC"
    
    REM Generate passwords
    for /f %%i in ('powershell -Command "Add-Type -AssemblyName System.Web; [System.Web.Security.Membership]::GeneratePassword(32, 4)"') do set "mysql_root=%%i"
    for /f %%i in ('powershell -Command "Add-Type -AssemblyName System.Web; [System.Web.Security.Membership]::GeneratePassword(32, 4)"') do set "mysql_mail=%%i"
    
    REM Write to .env file
    echo MAIL_DOMAIN=%domain% >> .env
    echo MAIL_HOSTNAME=%hostname% >> .env
    echo ADMIN_EMAIL=%admin_email% >> .env
    echo MYSQL_ROOT_PASSWORD=%mysql_root% >> .env
    echo MYSQL_MAIL_PASSWORD=%mysql_mail% >> .env
    echo TZ=%timezone% >> .env
    
    call :print_status "Environment file created: .env"
    call :print_warning "MySQL Root Password: %mysql_root%"
    call :print_warning "MySQL Mail Password: %mysql_mail%"
    echo Please save these passwords securely!
    echo.
) else (
    call :print_status "Environment file already exists: .env"
)
goto :eof

REM Function to start containers
:start_containers
call :print_header "Starting LibTMail Containers"

if not exist .env (
    call :print_warning "Environment file not found, creating one..."
    call :create_env_file
)

docker-compose up -d

if %errorlevel% equ 0 (
    call :print_status "Containers started successfully"
    call :show_status
) else (
    call :print_error "Failed to start containers"
    pause
    exit /b 1
)
goto :eof

REM Function to stop containers
:stop_containers
call :print_header "Stopping LibTMail Containers"

docker-compose down

call :print_status "Containers stopped"
goto :eof

REM Function to restart containers
:restart_containers
call :print_header "Restarting LibTMail Containers"

docker-compose restart

call :print_status "Containers restarted"
call :show_status
goto :eof

REM Function to show container status
:show_status
call :print_header "Container Status"

docker-compose ps

echo.
call :print_status "Service URLs:"
echo   Webmail: http://localhost:80
echo   HTTPS: https://localhost:443
echo   phpMyAdmin: http://localhost:8080 (if enabled)
echo   MailHog: http://localhost:8025 (if enabled)
goto :eof

REM Function to show logs
:show_logs
set "service=%1"

if "%service%"=="" (
    call :print_header "All Logs"
    docker-compose logs -f
) else (
    call :print_header "Logs for %service%"
    docker-compose logs -f %service%
)
goto :eof

REM Function to execute command in container
:exec_command
set "service=%1"
shift

if "%service%"=="" (
    call :print_error "Service name is required"
    echo Usage: %0 exec ^<service^> ^<command^>
    echo Available services: libtmail
    pause
    exit /b 1
)

call :print_header "Executing in %service%"
docker-compose exec %service% %*
goto :eof

REM Function to backup data
:backup_data
call :print_header "Backing Up Data"

set "backup_dir=backups\%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "backup_dir=%backup_dir: =0%"

mkdir "%backup_dir%" 2>nul

REM Backup volumes (simplified for Windows)
call :print_status "Backing up to %backup_dir%"

REM Copy configuration files
copy .env "%backup_dir%\" >nul
copy docker-compose.yml "%backup_dir%\" >nul

REM Export data volumes
docker run --rm -v libtmail_mail_data:/data -v "%cd%\%backup_dir%":/backup alpine tar czf /backup/mail_data.tar.gz -C /data .
docker run --rm -v libtmail_mysql_data:/data -v "%cd%\%backup_dir%":/backup alpine tar czf /backup/mysql_data.tar.gz -C /data .
docker run --rm -v libtmail_ssl_certs:/data -v "%cd%\%backup_dir%":/backup alpine tar czf /backup/ssl_certs.tar.gz -C /data .

call :print_status "Backup completed: %backup_dir%"
goto :eof

REM Function to restore data
:restore_data
set "backup_dir=%1"

if "%backup_dir%"=="" (
    call :print_error "Backup directory is required"
    echo Usage: %0 restore ^<backup_directory^>
    pause
    exit /b 1
)

if not exist "%backup_dir%" (
    call :print_error "Backup directory not found: %backup_dir%"
    pause
    exit /b 1
)

call :print_header "Restoring Data from %backup_dir%"

REM Stop containers
docker-compose down

REM Restore volumes
docker run --rm -v libtmail_mail_data:/data -v "%cd%\%backup_dir%":/backup alpine tar xzf /backup/mail_data.tar.gz -C /data
docker run --rm -v libtmail_mysql_data:/data -v "%cd%\%backup_dir%":/backup alpine tar xzf /backup/mysql_data.tar.gz -C /data
docker run --rm -v libtmail_ssl_certs:/data -v "%cd%\%backup_dir%":/backup alpine tar xzf /backup/ssl_certs.tar.gz -C /data

REM Restore configuration files
copy "%backup_dir%\.env" . >nul
copy "%backup_dir%\docker-compose.yml" . >nul

REM Start containers
docker-compose up -d

call :print_status "Data restored successfully"
goto :eof

REM Function to update containers
:update_containers
call :print_header "Updating LibTMail Containers"

REM Pull latest images
docker-compose pull

REM Rebuild and restart
docker-compose up -d --build

call :print_status "Containers updated"
call :show_status
goto :eof

REM Function to clean up
:cleanup
call :print_header "Cleaning Up Docker Resources"

REM Remove stopped containers
docker-compose down --remove-orphans

REM Remove unused images
docker image prune -f

REM Remove unused volumes (be careful!)
set /p "confirm=Remove unused volumes? This may delete data! (y/N): "
if /i "%confirm%"=="y" (
    docker volume prune -f
)

call :print_status "Cleanup completed"
goto :eof

REM Function to show usage
:show_usage
echo LibTMail Docker Management Script for Windows
echo.
echo Usage: %0 [command] [options]
echo.
echo Commands:
echo   start           Start all containers
echo   stop            Stop all containers
echo   restart         Restart all containers
echo   status          Show container status
echo   logs [service]  Show logs (all or specific service)
echo   exec ^<cmd^>      Execute command in libtmail container
echo   backup          Backup all data
echo   restore ^<dir^>   Restore data from backup
echo   update          Update containers
echo   cleanup         Clean up Docker resources
echo   env             Create/update environment file
echo   help            Show this help
echo.
echo Examples:
echo   %0 start
echo   %0 logs libtmail
echo   %0 exec mailadmin list
echo   %0 exec mysql -u root -p mailserver
echo   %0 backup
echo   %0 restore backups\20231201_120000
echo.
goto :eof

REM Main function
:main
set "command=%1"

if "%command%"=="" goto show_usage

if "%command%"=="start" (
    call :check_docker
    call :create_env_file
    call :start_containers
) else if "%command%"=="stop" (
    call :check_docker
    call :stop_containers
) else if "%command%"=="restart" (
    call :check_docker
    call :restart_containers
) else if "%command%"=="status" (
    call :check_docker
    call :show_status
) else if "%command%"=="logs" (
    call :check_docker
    call :show_logs %2
) else if "%command%"=="exec" (
    call :check_docker
    shift
    call :exec_command %*
) else if "%command%"=="backup" (
    call :check_docker
    call :backup_data
) else if "%command%"=="restore" (
    call :check_docker
    call :restore_data %2
) else if "%command%"=="update" (
    call :check_docker
    call :update_containers
) else if "%command%"=="cleanup" (
    call :check_docker
    call :cleanup
) else if "%command%"=="env" (
    call :create_env_file
) else if "%command%"=="help" (
    call :show_usage
) else (
    call :print_error "Unknown command: %command%"
    call :show_usage
    pause
    exit /b 1
)

pause
goto :eof

REM Run main function
call :main %*

endlocal
