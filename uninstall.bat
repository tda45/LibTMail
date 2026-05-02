@echo off
REM LibTMail Mail Server Uninstall Script for Windows
REM This script completely removes the mail server and all its components
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
set "BACKUP_DIR=C:\ProgramData\mailserver_uninstall_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "LOG_FILE=%TEMP%\libtmail_uninstall.log"

REM Function to print colored output
:print_status
echo %GREEN%[INFO]%NC% %~1
echo %date% %time% - [INFO] %~1 >> "%LOG_FILE%"
goto :eof

:print_warning
echo %YELLOW%[WARNING]%NC% %~1
echo %date% %time% - [WARNING] %~1 >> "%LOG_FILE%"
goto :eof

:print_error
echo %RED%[ERROR]%NC% %~1
echo %date% %time% - [ERROR] %~1 >> "%LOG_FILE%"
goto :eof

:print_header
echo %BLUE%================================%NC%
echo %BLUE%%~1%NC%
echo %BLUE%================================%NC%
echo %date% %time% - %~1 >> "%LOG_FILE%"
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

REM Function to check if mail server is installed
:check_installation
call :print_header "Checking Mail Server Installation"

set "installed=false"

REM Check for main components
if exist "C:\Program Files\hMailServer\Bin\hMailServer.exe" (
    call :print_status "hMailServer is installed"
    set "installed=true"
)

if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" (
    call :print_status "MySQL is installed"
    set "installed=true"
)

if exist "C:\ProgramData\hMailServer" (
    call :print_status "hMailServer data directory exists"
    set "installed=true"
)

if exist "C:\vmail" (
    call :print_status "Mail data directory exists"
    set "installed=true"
)

if "%installed%"=="false" (
    call :print_warning "No mail server installation detected"
    set /p "continue=Do you want to continue anyway? (y/N): "
    if /i not "%continue%"=="y" (
        call :print_status "Uninstall cancelled"
        pause
        exit /b 0
    )
)
goto :eof

REM Function to create backup
:create_backup
call :print_header "Creating Backup"

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM Backup configurations
if exist "C:\ProgramData\hMailServer\hMailServer.ini" (
    call :print_status "Backing up hMailServer configuration..."
    copy "C:\ProgramData\hMailServer\hMailServer.ini" "%BACKUP_DIR%\" >nul
)

if exist "C:\ProgramData\hMailServer\Data" (
    call :print_status "Backing up hMailServer data..."
    xcopy "C:\ProgramData\hMailServer\Data" "%BACKUP_DIR%\hMailServer_Data\" /E /I /H /Y >nul
)

if exist "C:\ProgramData\MySQL\MySQL Server 8.0\my.ini" (
    call :print_status "Backing up MySQL configuration..."
    copy "C:\ProgramData\MySQL\MySQL Server 8.0\my.ini" "%BACKUP_DIR%\" >nul
)

REM Backup mail data
if exist "C:\vmail" (
    call :print_status "Backing up mail data..."
    xcopy "C:\vmail" "%BACKUP_DIR%\vmail\" /E /I /H /Y >nul
)

REM Backup SSL certificates
if exist "C:\ProgramData\mailserver\certs" (
    call :print_status "Backing up SSL certificates..."
    xcopy "C:\ProgramData\mailserver\certs" "%BACKUP_DIR%\ssl_certs\" /E /I /H /Y >nul
)

if exist "C:\ProgramData\mailserver\private" (
    call :print_status "Backing up SSL keys..."
    xcopy "C:\ProgramData\mailserver\private" "%BACKUP_DIR%\ssl_private\" /E /I /H /Y >nul
)

REM Backup management scripts
if exist "C:\ProgramData\mailserver\mailadmin.bat" (
    copy "C:\ProgramData\mailserver\mailadmin.bat" "%BACKUP_DIR%\" >nul
)

if exist "C:\ProgramData\mailserver\mailbackup.bat" (
    copy "C:\ProgramData\mailserver\mailbackup.bat" "%BACKUP_DIR%\" >nul
)

REM Backup scheduled tasks
schtasks /query /tn "MailServerBackup" > "%BACKUP_DIR%\scheduled_task.txt" 2>nul

REM Backup database
if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe" (
    call :print_status "Backing up database..."
    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe" --single-transaction --routines --triggers mailserver > "%BACKUP_DIR%\mailserver_backup.sql" 2>nul
)

call :print_status "Backup created at: %BACKUP_DIR%"
call :print_warning "Save this backup directory if you want to restore later!"
goto :eof

REM Function to stop services
:stop_services
call :print_header "Stopping Services"

REM Stop mail services
net stop hmailserver >nul 2>&1
net stop mysql >nul 2>&1

REM Disable services
sc config hmailserver start=disabled >nul 2>&1
sc config mysql start=disabled >nul 2>&1

call :print_status "Services stopped and disabled"
goto :eof

REM Function to remove programs
:remove_programs
call :print_header "Removing Programs"

REM Remove hMailServer
if exist "C:\Program Files\hMailServer\uninstall.exe" (
    call :print_status "Uninstalling hMailServer..."
    "C:\Program Files\hMailServer\uninstall.exe" /S >nul 2>&1
)

REM Remove MySQL
if exist "C:\Program Files\MySQL\MySQL Server 8.0\uninstall.exe" (
    call :print_status "Uninstalling MySQL..."
    "C:\Program Files\MySQL\MySQL Server 8.0\uninstall.exe" /S >nul 2>&1
)

REM Remove via Chocolatey if available
where choco >nul 2>&1
if %errorlevel% equ 0 (
    call :print_status "Removing packages via Chocolatey..."
    choco uninstall hmailserver mysql --yes >nul 2>&1
)

call :print_status "Programs removed"
goto :eof

REM Function to remove configurations
:remove_configurations
call :print_header "Removing Configurations"

REM Remove configuration directories
set "config_dirs=C:\ProgramData\hMailServer C:\ProgramData\mailserver C:\ProgramData\MySQL"

for %%d in (%config_dirs%) do (
    if exist "%%d" (
        call :print_status "Removing %%d..."
        rmdir /S /Q "%%d" >nul 2>&1
    )
)

REM Remove configuration files
set "config_files=C:\Windows\System32\drivers\etc\hosts.mail C:\ProgramData\mailserver.ini"

for %%f in (%config_files%) do (
    if exist "%%f" (
        call :print_status "Removing %%f..."
        del /F /Q "%%f" >nul 2>&1
    )
)

call :print_status "Configurations removed"
goto :eof

REM Function to remove mail data
:remove_mail_data
call :print_header "Removing Mail Data"

REM Remove mail directories
set "mail_dirs=C:\vmail C:\ProgramData\hMailServer\Data C:\ProgramData\mailserver\logs C:\ProgramData\mailserver\backups"

for %%d in (%mail_dirs%) do (
    if exist "%%d" (
        call :print_status "Removing %%d..."
        rmdir /S /Q "%%d" >nul 2>&1
    )
)

REM Remove log files
del /F /Q "C:\ProgramData\hMailServer\Logs\*" >nul 2>&1
del /F /Q "C:\Windows\Logs\MailServer\*" >nul 2>&1

call :print_status "Mail data removed"
goto :eof

REM Function to remove database
:remove_database
call :print_header "Removing Database"

REM Try to start MySQL temporarily
net start mysql >nul 2>&1

if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" (
    REM Remove mailserver database
    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -e "DROP DATABASE IF EXISTS mailserver;" >nul 2>&1
    
    REM Remove mailuser
    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -e "DROP USER IF EXISTS 'mailuser'@'localhost';" >nul 2>&1
    
    REM Flush privileges
    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -e "FLUSH PRIVILEGES;" >nul 2>&1
)

REM Stop MySQL again
net stop mysql >nul 2>&1

call :print_status "Database removed"
goto :eof

REM Function to remove services
:remove_services
call :print_header "Removing Services"

REM Remove Windows services
sc delete hmailserver >nul 2>&1
sc delete mysql >nul 2>&1

call :print_status "Services removed"
goto :eof

REM Function to remove management scripts
:remove_management_scripts
call :print_header "Removing Management Scripts"

set "scripts=C:\ProgramData\mailserver\mailadmin.bat C:\ProgramData\mailserver\mailbackup.bat"

for %%s in (%scripts%) do (
    if exist "%%s" (
        call :print_status "Removing %%s..."
        del /F /Q "%%s" >nul 2>&1
    )
)

REM Remove mailserver directory if empty
if exist "C:\ProgramData\mailserver" (
    rmdir "C:\ProgramData\mailserver" >nul 2>&1
)

call :print_status "Management scripts removed"
goto :eof

REM Function to remove scheduled tasks
:remove_scheduled_tasks
call :print_header "Removing Scheduled Tasks"

schtasks /delete /tn "MailServerBackup" /f >nul 2>&1

call :print_status "Scheduled tasks removed"
goto :eof

REM Function to remove SSL certificates
:remove_ssl_certificates
call :print_header "Removing SSL Certificates"

REM Remove certificates from Windows certificate store
powershell -Command "Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like '*%DOMAIN%*'} | Remove-Item -Force" >nul 2>&1

call :print_status "SSL certificates removed"
goto :eof

REM Function to clean firewall rules
:clean_firewall
call :print_header "Cleaning Firewall Rules"

REM Remove firewall rules
netsh advfirewall firewall delete rule name="SMTP" >nul 2>&1
netsh advfirewall firewall delete rule name="SMTPS" >nul 2>&1
netsh advfirewall firewall delete rule name="SMTPS_SSL" >nul 2>&1
netsh advfirewall firewall delete rule name="IMAP" >nul 2>&1
netsh advfirewall firewall delete rule name="IMAPS" >nul 2>&1
netsh advfirewall firewall delete rule name="POP3" >nul 2>&1
netsh advfirewall firewall delete rule name="POP3S" >nul 2>&1
netsh advfirewall firewall delete rule name="HTTP" >nul 2>&1
netsh advfirewall firewall delete rule name="HTTPS" >nul 2>&1

call :print_status "Firewall rules cleaned"
goto :eof

REM Function to clean registry entries
:clean_registry
call :print_header "Cleaning Registry Entries"

REM Remove hMailServer registry entries
reg delete "HKLM\SOFTWARE\hMailServer" /f >nul 2>&1

REM Remove MySQL registry entries
reg delete "HKLM\SOFTWARE\MySQL AB" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\MySQL AB" /f >nul 2>&1

call :print_status "Registry entries cleaned"
goto :eof

REM Function to clean remaining files
:clean_remaining_files
call :print_header "Cleaning Remaining Files"

REM Remove temporary files
del /F /Q "%TEMP%\*mail*" >nul 2>&1
del /F /Q "%TEMP%\*hmail*" >nul 2>&1
del /F /Q "%TEMP%\*mysql*" >nul 2>&1

REM Remove desktop shortcuts
del /F /Q "%PUBLIC%\Desktop\hMailServer*" >nul 2>&1
del /F /Q "%PUBLIC%\Desktop\MySQL*" >nul 2>&1

REM Remove start menu shortcuts
rmdir /S /Q "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\hMailServer" >nul 2>&1
rmdir /S /Q "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\MySQL" >nul 2>&1

call :print_status "Remaining files cleaned"
goto :eof

REM Function to show summary
:show_summary
call :print_header "Uninstall Summary"

echo %GREEN%LibTMail mail server has been successfully removed from Windows!%NC%
echo.
echo Removed Components:
echo   ✓ hMailServer mail server
echo   ✓ MySQL database
echo   ✓ SSL certificates
echo   ✓ Management scripts
echo   ✓ Scheduled tasks
echo   ✓ Firewall rules
echo   ✓ Registry entries
echo   ✓ Mail data and logs
echo   ✓ Configuration files
echo   ✓ Windows services
echo.
echo %YELLOW%Backup Location:%NC% %BACKUP_DIR%
echo %YELLOW%Uninstall Log:%NC% %LOG_FILE%
echo.
echo To restore your mail server in the future:
echo 1. Keep the backup directory safe
echo 2. Use the backup files to restore configurations
echo 3. Restore the database from the SQL dump
echo 4. Copy back the mail data
echo.
call :print_warning "Make sure to update your DNS records if you're decommissioning the server!"
echo.
call :print_status "Uninstall completed successfully!"
pause
goto :eof

REM Function to confirm uninstall
:confirm_uninstall
call :print_header "Uninstall Confirmation"

echo %RED%WARNING: This will completely remove the mail server and all data!%NC%
echo.
echo This uninstall will remove:
echo   • All mail server programs (hMailServer, MySQL, etc.)
echo   • All configuration files
echo   • All mail data and user accounts
echo   • Database and all email data
echo   • SSL certificates
echo   • Management scripts
echo   • Scheduled tasks
echo   • Windows services
echo   • Registry entries
echo   • Firewall rules
echo.
echo %YELLOW%A backup will be created at: %BACKUP_DIR%%NC%
echo.
set /p "confirm=Are you absolutely sure you want to continue? (Type 'yes' to confirm): "
echo.

if /i not "%confirm%"=="yes" (
    call :print_status "Uninstall cancelled by user"
    pause
    exit /b 0
)
goto :eof

REM Main function
:main
call :print_header "LibTMail Mail Server Uninstall Script for Windows"

call :check_admin
call :detect_windows
call :check_installation
call :confirm_uninstall
call :create_backup
call :stop_services
call :remove_programs
call :remove_configurations
call :remove_mail_data
call :remove_database
call :remove_services
call :remove_management_scripts
call :remove_scheduled_tasks
call :remove_ssl_certificates
call :clean_firewall
call :clean_registry
call :clean_remaining_files
call :show_summary

goto :eof

REM Run main function
call :main

endlocal
