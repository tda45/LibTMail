@echo off
REM LibTMail Mail Server Configuration Script for Windows
REM This script configures a complete mail server on Windows systems
REM Author: tda_45
REM Version: 1.0

setlocal enabledelayedexpansion

REM Colors for output
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

REM Global variables
set "DOMAIN="
set "HOSTNAME="
set "ADMIN_EMAIL="
set "MYSQL_ROOT_PASSWORD="
set "MYSQL_MAIL_PASSWORD="
set "SSL_CERT_PATH=C:\ProgramData\mailserver\certs"
set "SSL_KEY_PATH=C:\ProgramData\mailserver\private"

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

REM Function to check if running as administrator
:check_admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "This script must be run as Administrator"
    pause
    exit /b 1
)
goto :eof

REM Function to detect Windows version
:detect_windows
call :print_header "Detecting Windows Version"

for /f "tokens=4-5 delims=. " %%i in ('ver') do set "VERSION=%%i.%%j"
if "%version%" == "10.0" (
    call :print_status "Detected Windows 10/11"
    set "WIN_VERSION=10"
) else if "%version%" == "6.3" (
    call :print_status "Detected Windows 8.1"
    set "WIN_VERSION=8"
) else if "%version%" == "6.1" (
    call :print_status "Detected Windows 7"
    set "WIN_VERSION=7"
) else (
    call :print_error "Unsupported Windows version: %version%"
    pause
    exit /b 1
)
goto :eof

REM Function to check if Chocolatey is installed
:check_chocolatey
where choco >nul 2>&1
if %errorlevel% neq 0 (
    call :print_status "Installing Chocolatey..."
    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    if %errorlevel% neq 0 (
        call :print_error "Failed to install Chocolatey"
        pause
        exit /b 1
    )
    call :print_status "Chocolatey installed successfully"
) else (
    call :print_status "Chocolatey is already installed"
)
goto :eof

REM Function to get user input
:get_user_input
call :print_header "Configuration Parameters"

echo Please enter the following information:
echo.

REM Get domain name
:domain_loop
set /p "DOMAIN=Enter your domain name (e.g., example.com): "
if "%DOMAIN%"=="" (
    call :print_error "Please enter a domain name"
    goto domain_loop
)

REM Get hostname
set /p "HOSTNAME=Enter hostname (e.g., mail): "
if "%HOSTNAME%"=="" set "HOSTNAME=mail"

REM Get admin email
:email_loop
set /p "ADMIN_EMAIL=Enter admin email address: "
if "%ADMIN_EMAIL%"=="" (
    call :print_error "Please enter an email address"
    goto email_loop
)

REM Generate random passwords
call :print_status "Generating random passwords..."
for /f %%i in ('powershell -Command "Add-Type -AssemblyName System.Web; [System.Web.Security.Membership]::GeneratePassword(32, 4)"') do set "MYSQL_ROOT_PASSWORD=%%i"
for /f %%i in ('powershell -Command "Add-Type -AssemblyName System.Web; [System.Web.Security.Membership]::GeneratePassword(32, 4)"') do set "MYSQL_MAIL_PASSWORD=%%i"

call :print_status "Generated MySQL passwords"
call :print_warning "Save these passwords securely!"
echo MySQL Root Password: %MYSQL_ROOT_PASSWORD%
echo MySQL Mail Password: %MYSQL_MAIL_PASSWORD%
echo
pause
goto :eof

REM Function to create directories
:create_directories
call :print_header "Creating Directories"

set "MAIL_DIR=C:\ProgramData\mailserver"
set "VMAIL_DIR=C:\vmail"
set "LOG_DIR=C:\ProgramData\mailserver\logs"
set "BACKUP_DIR=C:\ProgramData\mailserver\backups"

if not exist "%MAIL_DIR%" mkdir "%MAIL_DIR%"
if not exist "%VMAIL_DIR%" mkdir "%VMAIL_DIR%"
if not exist "%SSL_CERT_PATH%" mkdir "%SSL_CERT_PATH%"
if not exist "%SSL_KEY_PATH%" mkdir "%SSL_KEY_PATH%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

call :print_status "Directories created successfully"
goto :eof

REM Function to install MySQL
:install_mysql
call :print_header "Installing MySQL Server"

choco install mysql --yes -params '"/InstallType=Server /ServerType=Config /Port=3306 /RootPassword=%MYSQL_ROOT_PASSWORD%"'
if %errorlevel% neq 0 (
    call :print_error "Failed to install MySQL"
    pause
    exit /b 1
)

REM Start MySQL service
net start mysql
sc config mysql start=auto

call :print_status "MySQL installed and started"
goto :eof

REM Function to create mail database
:create_mail_database
call :print_header "Creating Mail Database"

REM Create database and user
mysql -u root -p%MYSQL_ROOT_PASSWORD% -e "CREATE DATABASE IF NOT EXISTS mailserver;"
mysql -u root -p%MYSQL_ROOT_PASSWORD% -e "CREATE USER IF NOT EXISTS 'mailuser'@'localhost' IDENTIFIED BY '%MYSQL_MAIL_PASSWORD%';"
mysql -u root -p%MYSQL_ROOT_PASSWORD% -e "GRANT ALL PRIVILEGES ON mailserver.* TO 'mailuser'@'localhost';"
mysql -u root -p%MYSQL_ROOT_PASSWORD% -e "FLUSH PRIVILEGES;"

REM Create tables
mysql -u mailuser -p%MYSQL_MAIL_PASSWORD% mailserver < temp_create_tables.sql

call :print_status "Mail database created successfully"
goto :eof

REM Function to create SQL tables file
:create_sql_file
call :print_header "Creating SQL Tables File"

echo CREATE TABLE IF NOT EXISTS domains ( > temp_create_tables.sql
echo     id INT AUTO_INCREMENT PRIMARY KEY, >> temp_create_tables.sql
echo     name VARCHAR(255) NOT NULL UNIQUE >> temp_create_tables.sql
echo ); >> temp_create_tables.sql
echo. >> temp_create_tables.sql
echo CREATE TABLE IF NOT EXISTS users ( >> temp_create_tables.sql
echo     id INT AUTO_INCREMENT PRIMARY KEY, >> temp_create_tables.sql
echo     domain_id INT NOT NULL, >> temp_create_tables.sql
echo     email VARCHAR(255) NOT NULL UNIQUE, >> temp_create_tables.sql
echo     password VARCHAR(255) NOT NULL, >> temp_create_tables.sql
echo     FOREIGN KEY (domain_id) REFERENCES domains(id) >> temp_create_tables.sql
echo ); >> temp_create_tables.sql
echo. >> temp_create_tables.sql
echo CREATE TABLE IF NOT EXISTS aliases ( >> temp_create_tables.sql
echo     id INT AUTO_INCREMENT PRIMARY KEY, >> temp_create_tables.sql
echo     domain_id INT NOT NULL, >> temp_create_tables.sql
echo     source VARCHAR(255) NOT NULL, >> temp_create_tables.sql
echo     destination VARCHAR(255) NOT NULL, >> temp_create_tables.sql
echo     FOREIGN KEY (domain_id) REFERENCES domains(id) >> temp_create_tables.sql
echo ); >> temp_create_tables.sql
echo. >> temp_create_tables.sql
echo INSERT INTO domains (name) VALUES ('%DOMAIN%'); >> temp_create_tables.sql

call :print_status "SQL file created"
goto :eof

REM Function to install hMailServer
:install_hmailserver
call :print_header "Installing hMailServer"

REM Download hMailServer
powershell -Command "Invoke-WebRequest -Uri 'https://www.hmailserver.com/downloads/latest-release' -OutFile 'hmailserver.exe'"
if %errorlevel% neq 0 (
    call :print_error "Failed to download hMailServer"
    pause
    exit /b 1
)

REM Install hMailServer silently
hmailserver.exe /S
if %errorlevel% neq 0 (
    call :print_error "Failed to install hMailServer"
    pause
    exit /b 1
)

call :print_status "hMailServer installed"
goto :eof

REM Function to configure hMailServer
:configure_hmailserver
call :print_header "Configuring hMailServer"

REM Create hMailServer configuration script
echo Set oApp = CreateObject("hMailServer.Application") > configure_hmail.vbs
echo oApp.Authenticate "Administrator", "%MYSQL_ROOT_PASSWORD%" >> configure_hmail.vbs
echo. >> configure_hmail.vbs
echo Set oDomain = oApp.Domains.AddByName("%DOMAIN%") >> configure_hmail.vbs
echo oDomain.Active = True >> configure_hmail.vbs
echo oDomain.Save >> configure_hmail.vbs
echo. >> configure_hmail.vbs
echo Set oAccount = oDomain.Accounts.Add >> configure_hmail.vbs
echo oAccount.Address = "%ADMIN_EMAIL%" >> configure_hmail.vbs
echo oAccount.Password = "admin123" >> configure_hmail.vbs
echo oAccount.Active = True >> configure_hmail.vbs
echo oAccount.Save >> configure_hmail.vbs

REM Run configuration script
cscript configure_hmail.vbs
if %errorlevel% neq 0 (
    call :print_error "Failed to configure hMailServer"
    pause
    exit /b 1
)

REM Clean up
del configure_hmail.vbs

call :print_status "hMailServer configured"
goto :eof

REM Function to generate SSL certificate
:generate_ssl_certificate
call :print_header "Generating SSL Certificate"

REM Use OpenSSL to generate self-signed certificate
powershell -Command "& { $cert = New-SelfSignedCertificate -DnsName '%HOSTNAME%.%DOMAIN%' -CertStoreLocation 'cert:\LocalMachine\My' -KeyUsage KeyEncipherment,DigitalSignature -KeyLength 2048; Export-Certificate -Cert $cert -FilePath '%SSL_CERT_PATH%\mailserver.crt'; $pfx = Export-PfxCertificate -Cert $cert -FilePath '%SSL_KEY_PATH%\mailserver.pfx' -Password (ConvertTo-SecureString -String 'password' -Force -AsPlainText); }"

if %errorlevel% neq 0 (
    call :print_error "Failed to generate SSL certificate"
    pause
    exit /b 1
)

call :print_status "SSL certificate generated"
goto :eof

REM Function to configure firewall
:configure_firewall
call :print_header "Configuring Firewall"

REM Open necessary ports
netsh advfirewall firewall add rule name="SMTP" dir=in action=allow protocol=TCP localport=25
netsh advfirewall firewall add rule name="SMTPS" dir=in action=allow protocol=TCP localport=587
netsh advfirewall firewall add rule name="SMTPS_SSL" dir=in action=allow protocol=TCP localport=465
netsh advfirewall firewall add rule name="IMAP" dir=in action=allow protocol=TCP localport=143
netsh advfirewall firewall add rule name="IMAPS" dir=in action=allow protocol=TCP localport=993
netsh advfirewall firewall add rule name="POP3" dir=in action=allow protocol=TCP localport=110
netsh advfirewall firewall add rule name="POP3S" dir=in action=allow protocol=TCP localport=995
netsh advfirewall firewall add rule name="HTTP" dir=in action=allow protocol=TCP localport=80
netsh advfirewall firewall add rule name="HTTPS" dir=in action=allow protocol=TCP localport=443

call :print_status "Firewall rules configured"
goto :eof

REM Function to start services
:start_services
call :print_header "Starting Services"

REM Start MySQL
net start mysql

REM Start hMailServer
net start hmailserver

call :print_status "Services started"
goto :eof

REM Function to create admin user
:create_admin_user
call :print_header "Creating Admin Email User"

REM Generate password for admin user
for /f %%i in ('powershell -Command "Add-Type -AssemblyName System.Web; [System.Web.Security.Membership]::GeneratePassword(16, 3)"') do set "ADMIN_PASSWORD=%%i"

REM Create admin user in database
mysql -u mailuser -p%MYSQL_MAIL_PASSWORD% mailserver -e "INSERT INTO users (domain_id, email, password) VALUES (1, '%ADMIN_EMAIL%', PASSWORD('%ADMIN_PASSWORD%'));"

call :print_status "Admin email user created"
call :print_warning "Admin Email: %ADMIN_EMAIL%"
call :print_warning "Admin Password: %ADMIN_PASSWORD%"
echo Please save these credentials securely!
pause
goto :eof

REM Function to create user management script
:create_user_management_script
call :print_header "Creating User Management Script"

echo @echo off > mailadmin.bat
echo REM Mail User Management Script for Windows >> mailadmin.bat
echo. >> mailadmin.bat
echo if "%1"=="add" goto add_user >> mailadmin.bat
echo if "%1"=="delete" goto delete_user >> mailadmin.bat
echo if "%1"=="list" goto list_users >> mailadmin.bat
echo if "%1"=="password" goto change_password >> mailadmin.bat
echo goto usage >> mailadmin.bat
echo. >> mailadmin.bat
echo :add_user >> mailadmin.bat
echo if "%2"=="" goto usage >> mailadmin.bat
echo if "%3"=="" goto usage >> mailadmin.bat
echo mysql -u mailuser -p%MYSQL_MAIL_PASSWORD% mailserver -e "INSERT INTO users (domain_id, email, password) VALUES ((SELECT id FROM domains WHERE name='%DOMAIN%'), '%2', PASSWORD('%3'));" >> mailadmin.bat
echo echo User %2 added successfully >> mailadmin.bat
echo goto end >> mailadmin.bat
echo. >> mailadmin.bat
echo :delete_user >> mailadmin.bat
echo if "%2"=="" goto usage >> mailadmin.bat
echo mysql -u mailuser -p%MYSQL_MAIL_PASSWORD% mailserver -e "DELETE FROM users WHERE email='%2';" >> mailadmin.bat
echo echo User %2 deleted successfully >> mailadmin.bat
echo goto end >> mailadmin.bat
echo. >> mailadmin.bat
echo :list_users >> mailadmin.bat
echo echo Email users for domain %DOMAIN%: >> mailadmin.bat
echo mysql -u mailuser -p%MYSQL_MAIL_PASSWORD% mailserver -e "SELECT email FROM users;" >> mailadmin.bat
echo goto end >> mailadmin.bat
echo. >> mailadmin.bat
echo :change_password >> mailadmin.bat
echo if "%2"=="" goto usage >> mailadmin.bat
echo if "%3"=="" goto usage >> mailadmin.bat
echo mysql -u mailuser -p%MYSQL_MAIL_PASSWORD% mailserver -e "UPDATE users SET password=PASSWORD('%3') WHERE email='%2';" >> mailadmin.bat
echo echo Password changed for %2 >> mailadmin.bat
echo goto end >> mailadmin.bat
echo. >> mailadmin.bat
echo :usage >> mailadmin.bat
echo echo Usage: mailadmin.bat {add^|delete^|list^|password} >> mailadmin.bat
echo echo   add email@%DOMAIN% password     - Add new user >> mailadmin.bat
echo echo   delete email@%DOMAIN%           - Delete user >> mailadmin.bat
echo echo   list                            - List all users >> mailadmin.bat
echo echo   password email@%DOMAIN% newpass - Change user password >> mailadmin.bat
echo. >> mailadmin.bat
echo :end >> mailadmin.bat

move mailadmin.bat "C:\ProgramData\mailserver\mailadmin.bat"

call :print_status "User management script created: C:\ProgramData\mailserver\mailadmin.bat"
goto :eof

REM Function to create backup script
:create_backup_script
call :print_header "Creating Backup Script"

echo @echo off > mailbackup.bat
echo REM Mail Server Backup Script for Windows >> mailbackup.bat
echo set "BACKUP_DIR=C:\ProgramData\mailserver\backups" >> mailbackup.bat
echo set "DATE=%%date:~-4,4%%date:~-7,2%%date:~-10,2%%time:~0,2%%time:~3,2%%time:~6,2%" >> mailbackup.bat
echo set "BACKUP_FILE=%%BACKUP_DIR%%\mailserver_backup_%%DATE%%.zip" >> mailbackup.bat
echo. >> mailbackup.bat
echo echo Creating backup... >> mailbackup.bat
echo mysqldump --single-transaction --routines --triggers -u mailuser -p%MYSQL_MAIL_PASSWORD% mailserver > "%%BACKUP_DIR%%\mailserver_%%DATE%%.sql" >> mailbackup.bat
echo powershell -Command "Compress-Archive -Path 'C:\ProgramData\mailserver\*' -DestinationPath '%%BACKUP_FILE%%' -Force" >> mailbackup.bat
echo echo Backup completed: %%BACKUP_FILE%% >> mailbackup.bat

move mailbackup.bat "C:\ProgramData\mailserver\mailbackup.bat"

REM Create scheduled task for daily backup
schtasks /create /tn "MailServerBackup" /tr "C:\ProgramData\mailserver\mailbackup.bat" /sc daily /st 02:00 /f

call :print_status "Backup script created and scheduled"
goto :eof

REM Function to test configuration
:test_configuration
call :print_header "Testing Configuration"

REM Test MySQL connection
mysql -u mailuser -p%MYSQL_MAIL_PASSWORD% mailserver -e "SELECT 1;" >nul 2>&1
if %errorlevel% equ 0 (
    call :print_status "MySQL connection successful"
) else (
    call :print_error "MySQL connection failed"
)

REM Test hMailServer
sc query hmailserver | find "RUNNING" >nul
if %errorlevel% equ 0 (
    call :print_status "hMailServer is running"
) else (
    call :print_error "hMailServer is not running"
)

call :print_status "Configuration test completed"
goto :eof

REM Function to display final information
:display_final_info
call :print_header "Installation Complete!"

echo %GREEN%Your mail server has been successfully configured on Windows!%NC%
echo.
echo Server Information:
echo   Domain: %DOMAIN%
echo   Hostname: %HOSTNAME%.%DOMAIN%
echo   Admin Email: %ADMIN_EMAIL%
echo.
echo Service Status:
echo   MySQL: Running
echo   hMailServer: Running
echo.
echo Open Ports:
echo   25   - SMTP
echo   587  - SMTP (Submission)
echo   143  - IMAP
echo   993  - IMAPS
echo   110  - POP3
echo   995  - POP3S
echo   80   - HTTP
echo   443  - HTTPS
echo.
echo Management Tools:
echo   mailadmin.bat - Manage email users
echo   mailbackup.bat - Backup mail server
echo.
echo Important Files:
echo   MySQL Data: C:\ProgramData\MySQL\MySQL Server 8.0\Data
echo   hMailServer Data: C:\ProgramData\hMailServer
echo   SSL Certificate: %SSL_CERT_PATH%\mailserver.crt
echo   SSL Key: %SSL_KEY_PATH%\mailserver.pfx
echo   Backup Directory: C:\ProgramData\mailserver\backups
echo.
echo Next Steps:
echo 1. Configure DNS MX records to point to your server
echo 2. Configure email clients with the server details
echo 3. Test email functionality
echo 4. Set up regular monitoring
echo.
echo Example DNS Records:
echo   MX    @    10    %HOSTNAME%.%DOMAIN%
echo   TXT   @    "v=spf1 mx -all"
echo.
call :print_warning "Remember to save your MySQL passwords securely!"
goto :eof

REM Main function
:main
call :print_header "LibTMail Mail Server Configuration Script for Windows"

call :check_admin
call :detect_windows
call :check_chocolatey
call :get_user_input
call :create_directories
call :install_mysql
call :create_sql_file
call :create_mail_database
call :install_hmailserver
call :configure_hmailserver
call :generate_ssl_certificate
call :configure_firewall
call :start_services
call :create_admin_user
call :create_user_management_script
call :create_backup_script
call :test_configuration
call :display_final_info

REM Clean up temporary files
if exist temp_create_tables.sql del temp_create_tables.sql
if exist hmailserver.exe del hmailserver.exe

call :print_status "Windows mail server configuration completed successfully!"
pause
goto :eof

REM Run main function
call :main

endlocal
