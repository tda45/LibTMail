@echo off
REM LibTMail Configuration Validation Tool for Windows
REM Validates mail server configuration and detects potential issues
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
set "VALIDATION_LOG=%TEMP%\libtmail_validation.log"
set "ISSUES_FOUND=0"
set "WARNINGS_FOUND=0"
set "CRITICAL_ERRORS=0"

REM Function to print colored output
:print_status
echo %GREEN%[INFO]%NC% %~1
echo %date% %time% - [INFO] %~1 >> "%VALIDATION_LOG%"
goto :eof

:print_warning
echo %YELLOW%[WARNING]%NC% %~1
echo %date% %time% - [WARNING] %~1 >> "%VALIDATION_LOG%"
set /a "WARNINGS_FOUND+=1"
goto :eof

:print_error
echo %RED%[ERROR]%NC% %~1
echo %date% %time% - [ERROR] %~1 >> "%VALIDATION_LOG%"
set /a "CRITICAL_ERRORS+=1"
goto :eof

:print_header
echo %BLUE%================================%NC%
echo %BLUE%%~1%NC%
echo %BLUE%================================%NC%
echo %date% %time% - %~1 >> "%VALIDATION_LOG%"
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

REM Function to initialize validation
:init_validation
call :print_header "LibTMail Configuration Validation"

REM Clear previous log
> "%VALIDATION_LOG%"
echo LibTMail Configuration Validation Report >> "%VALIDATION_LOG%"
echo Date: %date% >> "%VALIDATION_LOG%"
echo Time: %time% >> "%VALIDATION_LOG%"
echo Hostname: %COMPUTERNAME% >> "%VALIDATION_LOG%"
echo ================================ >> "%VALIDATION_LOG%"
goto :eof

REM Function to validate hMailServer configuration
validate_hmailserver
call :print_header "Validating hMailServer Configuration"

REM Check if hMailServer is installed
if exist "C:\Program Files\hMailServer\Bin\hMailServer.exe" (
    call :print_status "hMailServer is installed"
) else (
    call :print_error "hMailServer is not installed"
    goto :eof
)

REM Check configuration file
if exist "C:\ProgramData\hMailServer\hMailServer.ini" (
    call :print_status "hMailServer configuration file exists"
    
    REM Check critical settings
    findstr /C:"[Directories]" "C:\ProgramData\hMailServer\hMailServer.ini" >nul 2>&1
    if !errorlevel! equ 0 (
        call :print_status "Directories section found"
    ) else (
        call :print_warning "Directories section not found"
    )
    
    REM Check database settings
    findstr /C:"[Database]" "C:\ProgramData\hMailServer\hMailServer.ini" >nul 2>&1
    if !errorlevel! equ 0 (
        call :print_status "Database section found"
    ) else (
        call :print_warning "Database section not found"
    )
    
    REM Check security settings
    findstr /C:"[Security]" "C:\ProgramData\hMailServer\hMailServer.ini" >nul 2>&1
    if !errorlevel! equ 0 (
        call :print_status "Security section found"
    ) else (
        call :print_warning "Security section not found"
    )
) else (
    call :print_error "hMailServer configuration file not found"
)

REM Check service status
sc query hmailserver | find "RUNNING" >nul 2>&1
if !errorlevel! equ 0 (
    call :print_status "hMailServer service is running"
) else (
    call :print_error "hMailServer service is not running"
)

REM Check data directory
if exist "C:\ProgramData\hMailServer\Data" (
    call :print_status "hMailServer data directory exists"
) else (
    call :print_error "hMailServer data directory not found"
)

REM Check TCP/IP settings
if exist "C:\ProgramData\hMailServer\hMailServer.ini" (
    findstr /C:"TCPIPPort" "C:\ProgramData\hMailServer\hMailServer.ini" >nul 2>&1
    if !errorlevel! equ 0 (
        call :print_status "TCP/IP port configured"
    ) else (
        call :print_warning "TCP/IP port may not be configured"
    )
)
goto :eof

REM Function to validate MySQL configuration
validate_mysql
call :print_header "Validating MySQL Configuration"

REM Check if MySQL is installed
if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" (
    call :print_status "MySQL is installed"
) else (
    call :print_error "MySQL is not installed"
    goto :eof
)

REM Check service status
sc query mysql | find "RUNNING" >nul 2>&1
if !errorlevel! equ 0 (
    call :print_status "MySQL service is running"
) else (
    call :print_error "MySQL service is not running"
    goto :eof
)

REM Test root connection
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -e "SELECT 1;" >nul 2>&1
if !errorlevel! equ 0 (
    call :print_status "Root database connection successful"
) else (
    call :print_error "Cannot connect to database as root"
    goto :eof
)

REM Check mailserver database
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -e "USE mailserver;" >nul 2>&1
if !errorlevel! equ 0 (
    call :print_status "Mailserver database exists"
    
    REM Check tables
    for /f %%t in ('"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -e "USE mailserver; SHOW TABLES;" ^| find /c /v ""') do set "TABLE_COUNT=%%t"
    if !TABLE_COUNT! geq 3 (
        call :print_status "Found !TABLE_COUNT! tables in mailserver database"
    ) else (
        call :print_warning "Insufficient tables in mailserver database"
    )
    
    REM Check required tables
    set "required_tables=domains users aliases"
    for %%t in (!required_tables!) do (
        "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -e "USE mailserver; DESCRIBE %%t;" >nul 2>&1
        if !errorlevel! equ 0 (
            call :print_status "Table %%t exists"
        ) else (
            call :print_error "Required table %%t not found"
        )
    )
    
    REM Check data
    for /f %%d in ('"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -e "USE mailserver; SELECT COUNT(*) FROM domains;" ^| findstr [0-9]') do set "DOMAIN_COUNT=%%d"
    if !DOMAIN_COUNT! gtr 0 (
        call :print_status "Found !DOMAIN_COUNT! domain(s) configured"
    ) else (
        call :print_warning "No domains configured in database"
    )
    
    for /f %%u in ('"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -e "USE mailserver; SELECT COUNT(*) FROM users;" ^| findstr [0-9]') do set "USER_COUNT=%%u"
    if !USER_COUNT! gtr 0 (
        call :print_status "Found !USER_COUNT! user(s) configured"
    ) else (
        call :print_warning "No users configured in database"
    )
) else (
    call :print_error "Mailserver database does not exist"
)

REM Check mailuser
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -e "SELECT User FROM mysql.user WHERE User='mailuser';" >nul 2>&1
if !errorlevel! equ 0 (
    call :print_status "Mailuser exists"
    
    REM Test mailuser connection
    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u mailuser -e "SELECT 1;" >nul 2>&1
    if !errorlevel! equ 0 (
        call :print_status "Mailuser connection successful"
    ) else (
        call :print_warning "Mailuser connection failed"
    )
) else (
    call :print_error "Mailuser does not exist"
)
goto :eof

REM Function to validate SSL certificates
validate_ssl
call :print_header "Validating SSL Certificates"

set "cert_file=C:\ProgramData\mailserver\certs\mailserver.crt"
set "key_file=C:\ProgramData\mailserver\private\mailserver.pfx"

REM Check certificate file
if exist "%cert_file%" (
    call :print_status "SSL certificate file exists: %cert_file%"
    
    REM Check certificate in Windows store
    powershell -Command "Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like '*mail*'}" >nul 2>&1
    if !errorlevel! equ 0 (
        call :print_status "Certificate found in Windows certificate store"
    ) else (
        call :print_warning "Certificate not found in Windows certificate store"
    )
) else (
    call :print_error "SSL certificate file not found: %cert_file%"
)

REM Check key file
if exist "%key_file%" (
    call :print_status "SSL key file exists: %key_file%"
) else (
    call :print_error "SSL key file not found: %key_file%"
)

REM Check certificate details using PowerShell
if exist "%cert_file%" (
    powershell -Command "try { $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2('%cert_file%'); Write-Host 'Certificate valid until:' $cert.NotAfter; Write-Host 'Certificate subject:' $cert.Subject; Write-Host 'Certificate issuer:' $cert.Issuer } catch { Write-Host 'Error reading certificate:' $_.Exception.Message }" >> "%VALIDATION_LOG%" 2>&1
    
    for /f "tokens=*" %%i in ('powershell -Command "try { $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2('%cert_file%'); $cert.NotAfter.ToString('yyyy-MM-dd') } catch { 'INVALID' }"') do set "CERT_EXPIRY=%%i"
    
    if not "!CERT_EXPIRY!"=="INVALID" (
        call :print_status "Certificate valid until: !CERT_EXPIRY!"
    ) else (
        call :print_error "Cannot read certificate details"
    )
)
goto :eof

REM Function to validate mail directories
validate_directories
call :print_header "Validating Mail Directories"

set "directories=C:\vmail C:\ProgramData\hMailServer C:\ProgramData\mailserver"

for %%d in (%directories%) do (
    if exist "%%d" (
        call :print_status "Directory exists: %%d"
        
        REM Check disk space
        for /f "tokens=3" %%a in ('dir "%%d" ^| find "bytes free"') do (
            set "FREE_SPACE=%%a"
            set "FREE_SPACE=!FREE_SPACE:,=!"
        )
        set /a "DISK_GB=!FREE_SPACE:~0,-9!"
        call :print_status "Available disk space: !DISK_GB!GB"
    ) else (
        call :print_error "Directory not found: %%d"
    )
)
goto :eof

REM Function to validate firewall configuration
validate_firewall
call :print_header "Validating Firewall Configuration"

REM Check Windows Firewall
netsh advfirewall show allprofiles | find "State" | find "ON" >nul 2>&1
if !errorlevel! equ 0 (
    call :print_status "Windows Firewall is enabled"
    
    REM Check mail ports
    set "mail_ports=25 587 143 993 110 995 80 443"
    for %%p in (!mail_ports!) do (
        netsh advfirewall firewall show rule name="Port%%p" >nul 2>&1
        if !errorlevel! equ 0 (
            call :print_status "Port %%p rule exists"
        ) else (
            call :print_warning "Port %%p rule may not exist"
        )
    )
) else (
    call :print_warning "Windows Firewall is disabled"
)
goto :eof

REM Function to validate DNS configuration
validate_dns
call :print_header "Validating DNS Configuration"

REM Get domain from hMailServer configuration (simplified)
set "domain=example.com"
call :print_status "Using test domain: %domain%"

REM Check MX record
nslookup -type=mx %domain% >nul 2>&1
if !errorlevel! equ 0 (
    call :print_status "MX record found for %domain%"
) else (
    call :print_warning "No MX record found for %domain%"
)

REM Check A record
nslookup %domain% >nul 2>&1
if !errorlevel! equ 0 (
    call :print_status "A record found for %domain%"
) else (
    call :print_warning "No A record found for %domain%"
)

REM Check SPF record
nslookup -type=txt %domain% | find "v=spf1" >nul 2>&1
if !errorlevel! equ 0 (
    call :print_status "SPF record found for %domain%"
) else (
    call :print_warning "No SPF record found for %domain%"
)
goto :eof

REM Function to validate system resources
validate_system_resources
call :print_header "Validating System Resources"

REM Check memory usage
for /f "skip=1 delims== tokens=2" %%a in ('wmic computersystem get TotalPhysicalMemory /value') do (
    set /a "TOTAL_RAM=%%a/1024/1024"
    goto :ram_next
)
:ram_next
for /f "skip=1 delims== tokens=2" %%a in ('wmic OS get TotalVisibleMemorySize /value') do (
    set /a "AVAILABLE_RAM=%%a"
    goto :ram_available
)
:ram_available
set /a "RAM_USAGE=100 - (!AVAILABLE_RAM! * 100 / !TOTAL_RAM!)"

if !RAM_USAGE! lss 80 (
    call :print_status "Memory usage: !RAM_USAGE!%%"
) else (
    call :print_warning "High memory usage: !RAM_USAGE!%%"
)

REM Check disk usage
for /f "tokens=3" %%a in ('dir c:\ ^| find "bytes free"') do (
    set "FREE_SPACE=%%a"
    set "FREE_SPACE=!FREE_SPACE:,=!"
)
set /a "DISK_USAGE=100 - (!FREE_SPACE:~0,-9! * 100 / (!FREE_SPACE:~0,-9! + !FREE_SPACE:~0,-9!))"

if !DISK_USAGE! lss 80 (
    call :print_status "Disk usage: !DISK_USAGE!%%"
) else (
    call :print_warning "High disk usage: !DISK_USAGE!%%"
)

REM Check CPU usage
for /f "tokens=2 delims=," %%a in ('wmic cpu get loadpercentage /value ^| find "LoadPercentage"') do (
    set "CPU_USAGE=%%a"
    set "CPU_USAGE=!CPU_USAGE: =!"
)
if !CPU_USAGE! lss 80 (
    call :print_status "CPU usage: !CPU_USAGE!%%"
) else (
    call :print_warning "High CPU usage: !CPU_USAGE!%%"
)
goto :eof

REM Function to validate port availability
validate_ports
call :print_header "Validating Port Availability"

set "mail_ports=25:SMTP 587:SMTPS 143:IMAP 993:IMAPS 110:POP3 995:POP3S 80:HTTP 443:HTTPS"

for %%p in (%mail_ports%) do (
    for /f "tokens=1,2 delims=:" %%a in ("%%p") do (
        set "port_num=%%a"
        set "service=%%b"
        
        netstat -an | findstr ":%%a " >nul 2>&1
        if !errorlevel! equ 0 (
            call :print_status "Port %%a (%%b) is listening"
        ) else (
            call :print_warning "Port %%a (%%b) is not listening"
        )
    )
)
goto :eof

REM Function to validate management scripts
validate_management_scripts
call :print_header "Validating Management Scripts"

set "scripts=C:\ProgramData\mailserver\mailadmin.bat C:\ProgramData\mailserver\mailbackup.bat"

for %%s in (%scripts%) do (
    if exist "%%s" (
        call :print_status "Script %%~ns exists"
    ) else (
        call :print_warning "Script %%~ns not found"
    )
)
goto :eof

REM Function to generate validation report
generate_report
call :print_header "Validation Summary"

echo Issues Found: !ISSUES_FOUND!
echo Warnings: !WARNINGS_FOUND!
echo Critical Errors: !CRITICAL_ERRORS!
echo.

if !CRITICAL_ERRORS! gtr 0 (
    echo %RED%Status: CRITICAL ERRORS FOUND%NC%
    echo Please address critical errors before proceeding.
) else if !WARNINGS_FOUND! gtr 0 (
    echo %YELLOW%Status: WARNINGS FOUND%NC%
    echo Configuration is functional but may need attention.
) else (
    echo %GREEN%Status: VALID%NC%
    echo Configuration appears to be valid.
)

echo.
echo Detailed validation log saved to: %VALIDATION_LOG%

REM Show recommendations
if !CRITICAL_ERRORS! gtr 0 (
    echo.
    echo Recommendations:
    echo 1. Fix all critical errors immediately
    echo 2. Review warnings and address if necessary
    echo 3. Run validation again after making changes
    echo 4. Consider setting up monitoring for ongoing validation
)
goto :eof

REM Function to show usage
:show_usage
echo LibTMail Configuration Validation Tool for Windows
echo.
echo Usage: %~nx0 [options]
echo.
echo Options:
echo   -h, --help     Show this help message
echo   -q, --quick    Quick validation (basic checks only)
echo   -v, --verbose  Verbose output
echo   --hmailserver  Validate hMailServer only
echo   --mysql        Validate MySQL only
echo   --ssl          Validate SSL only
echo   --dns          Validate DNS only
echo   --system       Validate system resources only
echo   --ports        Validate port availability only
echo.
goto :eof

REM Main function
:main
set "validation_type=all"
set "quick_validation=false"

REM Parse command line arguments
if "%1"=="-h" goto show_usage
if "%1"=="--help" goto show_usage
if "%1"=="-q" set "quick_validation=true"
if "%1"=="--quick" set "quick_validation=true"
if "%1"=="--hmailserver" set "validation_type=hmailserver"
if "%1"=="--mysql" set "validation_type=mysql"
if "%1"=="--ssl" set "validation_type=ssl"
if "%1"=="--dns" set "validation_type=dns"
if "%1"=="--system" set "validation_type=system"
if "%1"=="--ports" set "validation_type=ports"

call :check_admin
call :init_validation

if "%validation_type%"=="hmailserver" (
    call :validate_hmailserver
) else if "%validation_type%"=="mysql" (
    call :validate_mysql
) else if "%validation_type%"=="ssl" (
    call :validate_ssl
) else if "%validation_type%"=="dns" (
    call :validate_dns
) else if "%validation_type%"=="system" (
    call :validate_system_resources
) else if "%validation_type%"=="ports" (
    call :validate_ports
) else (
    if "%quick_validation%"=="true" (
        call :validate_hmailserver
        call :validate_mysql
        call :validate_ssl
        call :validate_ports
    ) else (
        call :validate_hmailserver
        call :validate_mysql
        call :validate_ssl
        call :validate_directories
        call :validate_firewall
        call :validate_dns
        call :validate_system_resources
        call :validate_ports
        call :validate_management_scripts
    )
)

call :generate_report

if !CRITICAL_ERRORS! gtr 0 (
    exit /b 2
) else if !WARNINGS_FOUND! gtr 0 (
    exit /b 1
) else (
    exit /b 0
)
goto :eof

REM Run main function
call :main

endlocal
