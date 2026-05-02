@echo off
REM LibTMail Automated Testing Script for Windows
REM Comprehensive testing of mail server installation and functionality
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
set "TEST_LOG=%TEMP%\libtmail_test.log"
set "TOTAL_TESTS=0"
set "PASSED_TESTS=0"
set "FAILED_TESTS=0"
set "WARNING_TESTS=0"

REM Function to print colored output
:print_status
echo %GREEN%[INFO]%NC% %~1
echo %date% %time% - [INFO] %~1 >> "%TEST_LOG%"
goto :eof

:print_warning
echo %YELLOW%[WARNING]%NC% %~1
echo %date% %time% - [WARNING] %~1 >> "%TEST_LOG%"
goto :eof

:print_error
echo %RED%[ERROR]%NC% %~1
echo %date% %time% - [ERROR] %~1 >> "%TEST_LOG%"
goto :eof

:print_header
echo %BLUE%================================%NC%
echo %BLUE%%~1%NC%
echo %BLUE%================================%NC%
echo %date% %time% - %~1 >> "%TEST_LOG%"
goto :eof

REM Function to add test result
:add_test_result
set "test_name=%~1"
set "result=%~2"
set "message=%~3"

set /a "TOTAL_TESTS+=1"

if "%result%"=="PASS" (
    set /a "PASSED_TESTS+=1"
    echo %GREEN%[PASS]%NC% %test_name%: %message%
    echo [PASS] %test_name%: %message% >> "%TEST_LOG%"
) else if "%result%"=="FAIL" (
    set /a "FAILED_TESTS+=1"
    echo %RED%[FAIL]%NC% %test_name%: %message%
    echo [FAIL] %test_name%: %message% >> "%TEST_LOG%"
) else if "%result%"=="WARN" (
    set /a "WARNING_TESTS+=1"
    echo %YELLOW%[WARN]%NC% %test_name%: %message%
    echo [WARN] %test_name%: %message% >> "%TEST_LOG%"
)
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

REM Function to initialize test environment
:init_test_env
call :print_header "Initializing Test Environment"

REM Clear previous log
> "%TEST_LOG%"

REM Test date and time
echo LibTMail Automated Test Report >> "%TEST_LOG%"
echo Date: %date% >> "%TEST_LOG%"
echo Time: %time% >> "%TEST_LOG%"
echo Hostname: %COMPUTERNAME% >> "%TEST_LOG%"
echo OS: %OS% >> "%TEST_LOG%"
echo ================================ >> "%TEST_LOG%"

call :print_status "Test environment initialized"
goto :eof

REM Function to test system requirements
:test_system_requirements
call :print_header "Testing System Requirements"

REM Test OS version
for /f "tokens=4-5 delims=. " %%i in ('ver') do set "VERSION=%%i.%%j"
if "%version%" == "10.0" (
    call :add_test_result "OS Detection" "PASS" "Windows 10/11"
) else if "%version%" == "6.3" (
    call :add_test_result "OS Detection" "PASS" "Windows 8.1"
) else if "%version%" == "6.1" (
    call :add_test_result "OS Detection" "PASS" "Windows 7"
) else (
    call :add_test_result "OS Detection" "WARN" "Windows %version%"
)

REM Test architecture
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    call :add_test_result "Architecture" "PASS" "x64"
) else (
    call :add_test_result "Architecture" "WARN" "%PROCESSOR_ARCHITECTURE% (x64 recommended)"
)

REM Test RAM
for /f "skip=1 delims== tokens=2" %%a in ('wmic computersystem get TotalPhysicalMemory /value') do (
    set /a "RAM=%%a/1024/1024/1024"
    goto :ram_done
)
:ram_done
if %RAM% geq 2 (
    call :add_test_result "Memory" "PASS" "%RAM%GB"
) else (
    call :add_test_result "Memory" "WARN" "%RAM%GB (2GB+ recommended)"
)

REM Test disk space
for /f "tokens=3" %%a in ('dir c:\ ^| find "bytes free"') do (
    set "FREE_SPACE=%%a"
    set "FREE_SPACE=!FREE_SPACE:,=!"
)
set /a "DISK_GB=%FREE_SPACE:~0,-9%"
if %DISK_GB% geq 20 (
    call :add_test_result "Disk Space" "PASS" "%DISK_GB%GB"
) else (
    call :add_test_result "Disk Space" "WARN" "%DISK_GB%GB (20GB+ recommended)"
)

REM Test internet connection
ping -n 1 google.com >nul 2>&1
if %errorlevel% equ 0 (
    call :add_test_result "Internet Connection" "PASS" "Connected"
) else (
    call :add_test_result "Internet Connection" "FAIL" "No internet connection"
)
goto :eof

REM Function to test package installations
:test_package_installations
call :print_header "Testing Package Installations"

REM Test hMailServer
if exist "C:\Program Files\hMailServer\Bin\hMailServer.exe" (
    call :add_test_result "hMailServer" "PASS" "Installed"
) else (
    call :add_test_result "hMailServer" "FAIL" "Not installed"
)

REM Test MySQL
if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" (
    call :add_test_result "MySQL" "PASS" "Installed"
) else (
    call :add_test_result "MySQL" "FAIL" "Not installed"
)

REM Test Chocolatey
where choco >nul 2>&1
if %errorlevel% equ 0 (
    call :add_test_result "Chocolatey" "PASS" "Installed"
) else (
    call :add_test_result "Chocolatey" "WARN" "Not installed"
)

REM Test PowerShell
where powershell >nul 2>&1
if %errorlevel% equ 0 (
    call :add_test_result "PowerShell" "PASS" "Installed"
) else (
    call :add_test_result "PowerShell" "FAIL" "Not installed"
)
goto :eof

REM Function to test service status
:test_service_status
call :print_header "Testing Service Status"

REM Test hMailServer
sc query hmailserver | find "RUNNING" >nul 2>&1
if %errorlevel% equ 0 (
    call :add_test_result "hMailServer Service" "PASS" "Running"
) else (
    call :add_test_result "hMailServer Service" "FAIL" "Not running"
)

REM Test MySQL
sc query mysql | find "RUNNING" >nul 2>&1
if %errorlevel% equ 0 (
    call :add_test_result "MySQL Service" "PASS" "Running"
) else (
    call :add_test_result "MySQL Service" "FAIL" "Not running"
)
goto :eof

REM Function to test port availability
:test_port_availability
call :print_header "Testing Port Availability"

set "ports=25:SMTP 587:SMTPS 143:IMAP 993:IMAPS 110:POP3 995:POP3S 80:HTTP 443:HTTPS"

for %%p in (%ports%) do (
    set "port=%%p"
    for /f "tokens=1,2 delims=:" %%a in ("%%p") do (
        set "port_num=%%a"
        set "service=%%b"
        
        netstat -an | findstr ":%%a " >nul 2>&1
        if !errorlevel! equ 0 (
            call :add_test_result "Port %%a (%%b)" "PASS" "Open"
        ) else (
            call :add_test_result "Port %%a (%%b)" "FAIL" "Closed"
        )
    )
)
goto :eof

REM Function to test database connectivity
:test_database_connectivity
call :print_header "Testing Database Connectivity"

REM Test MySQL connection
if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" (
    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -e "SELECT 1;" >nul 2>&1
    if !errorlevel! equ 0 (
        call :add_test_result "MySQL Root Connection" "PASS" "Connected"
    ) else (
        call :add_test_result "MySQL Root Connection" "FAIL" "Cannot connect"
    )
    
    REM Test mailserver database
    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -e "USE mailserver; SHOW TABLES;" >nul 2>&1
    if !errorlevel! equ 0 (
        call :add_test_result "Mailserver Database" "PASS" "Database exists"
    ) else (
        call :add_test_result "Mailserver Database" "FAIL" "Database not found"
    )
    
    REM Test mailuser
    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u mailuser -e "SELECT 1;" >nul 2>&1
    if !errorlevel! equ 0 (
        call :add_test_result "Mailuser Connection" "PASS" "Connected"
    ) else (
        call :add_test_result "Mailuser Connection" "FAIL" "Cannot connect"
    )
) else (
    call :add_test_result "MySQL Testing" "WARN" "MySQL not installed"
)
goto :eof

REM Function to test SSL certificates
:test_ssl_certificates
call :print_header "Testing SSL Certificates"

set "cert_file=C:\ProgramData\mailserver\certs\mailserver.crt"
set "key_file=C:\ProgramData\mailserver\private\mailserver.pfx"

REM Test certificate file
if exist "%cert_file%" (
    call :add_test_result "SSL Certificate" "PASS" "Certificate file exists"
) else (
    call :add_test_result "SSL Certificate" "FAIL" "Certificate file not found"
)

REM Test key file
if exist "%key_file%" (
    call :add_test_result "SSL Key" "PASS" "Key file exists"
) else (
    call :add_test_result "SSL Key" "FAIL" "Key file not found"
)

REM Test certificate in Windows store
powershell -Command "Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like '*mail*'}" >nul 2>&1
if !errorlevel! equ 0 (
    call :add_test_result "SSL Certificate Store" "PASS" "Certificate found in store"
) else (
    call :add_test_result "SSL Certificate Store" "WARN" "Certificate not found in store"
)
goto :eof

REM Function to test mail directories
:test_mail_directories
call :print_header "Testing Mail Directories"

set "directories=C:\vmail C:\ProgramData\hMailServer C:\ProgramData\mailserver"

for %%d in (%directories%) do (
    if exist "%%d" (
        call :add_test_result "Directory %%d" "PASS" "Exists"
    ) else (
        call :add_test_result "Directory %%d" "FAIL" "Not found"
    )
)
goto :eof

REM Function to test configuration files
:test_configuration_files
call :print_header "Testing Configuration Files"

set "configs=C:\ProgramData\hMailServer\hMailServer.ini C:\ProgramData\MySQL\MySQL Server 8.0\my.ini"

for %%c in (%configs%) do (
    if exist "%%c" (
        call :add_test_result "Config %%~nc" "PASS" "Exists"
    ) else (
        call :add_test_result "Config %%~nc" "WARN" "Not found"
    )
)
goto :eof

REM Function to test management scripts
:test_management_scripts
call :print_header "Testing Management Scripts"

set "scripts=C:\ProgramData\mailserver\mailadmin.bat C:\ProgramData\mailserver\mailbackup.bat"

for %%s in (%scripts%) do (
    if exist "%%s" (
        call :add_test_result "Script %%~ns" "PASS" "Exists"
    ) else (
        call :add_test_result "Script %%~ns" "WARN" "Not found"
    )
)
goto :eof

REM Function to test webmail
:test_webmail
call :print_header "Testing Webmail"

if exist "C:\inetpub\wwwroot\webmail" (
    call :add_test_result "Webmail Directory" "PASS" "Exists"
    
    REM Test IIS
    sc query W3SVC | find "RUNNING" >nul 2>&1
    if !errorlevel! equ 0 (
        call :add_test_result "IIS Service" "PASS" "Running"
    ) else (
        call :add_test_result "IIS Service" "WARN" "Not running"
    )
) else (
    call :add_test_result "Webmail" "WARN" "Not installed"
)
goto :eof

REM Function to test DNS resolution
:test_dns_resolution
call :print_header "Testing DNS Resolution"

REM Get domain from configuration (simplified)
set "domain=example.com"

REM Test MX record
nslookup -type=mx %domain% >nul 2>&1
if !errorlevel! equ 0 (
    call :add_test_result "MX Record for %domain%" "PASS" "MX record found"
) else (
    call :add_test_result "MX Record for %domain%" "WARN" "No MX record found"
)

REM Test A record
nslookup %domain% >nul 2>&1
if !errorlevel! equ 0 (
    call :add_test_result "A Record for %domain%" "PASS" "A record found"
) else (
    call :add_test_result "A Record for %domain%" "WARN" "No A record found"
)
goto :eof

REM Function to test mail functionality
:test_mail_functionality
call :print_header "Testing Mail Functionality"

REM Test hMailServer connectivity
if exist "C:\Program Files\hMailServer\Bin\hMailServer.exe" (
    REM Test if hMailServer is responding
    telnet localhost 25 >nul 2>&1
    if !errorlevel! equ 0 (
        call :add_test_result "SMTP Connectivity" "PASS" "Port 25 responding"
    ) else (
        call :add_test_result "SMTP Connectivity" "FAIL" "Port 25 not responding"
    )
) else (
    call :add_test_result "Mail Functionality" "WARN" "hMailServer not installed"
)
goto :eof

REM Function to generate test report
:generate_test_report
call :print_header "Test Report Summary"

echo Total Tests: %TOTAL_TESTS%
echo Passed: %PASSED_TESTS%
echo Failed: %FAILED_TESTS%
echo Warnings: %WARNING_TESTS%

REM Calculate success rate
if %TOTAL_TESTS% gtr 0 (
    set /a "success_rate=%PASSED_TESTS% * 100 / %TOTAL_TESTS%"
    echo Success Rate: !success_rate!%%
    
    if !success_rate! geq 90 (
        echo %GREEN%Overall Status: EXCELLENT%NC%
    ) else if !success_rate! geq 75 (
        echo %YELLOW%Overall Status: GOOD%NC%
    ) else if !success_rate! geq 50 (
        echo %YELLOW%Overall Status: FAIR%NC%
    ) else (
        echo %RED%Overall Status: POOR%NC%
    )
)

echo.
echo Detailed log saved to: %TEST_LOG%
echo.

if %FAILED_TESTS% gtr 0 (
    echo Failed Tests:
    echo Failed: %FAILED_TESTS% tests need attention
)
goto :eof

REM Function to run all tests
:run_all_tests
call :print_header "Starting LibTMail Automated Tests"

call :init_test_env
call :test_system_requirements
call :test_package_installations
call :test_service_status
call :test_port_availability
call :test_database_connectivity
call :test_ssl_certificates
call :test_mail_directories
call :test_configuration_files
call :test_mail_functionality
call :test_management_scripts
call :test_webmail
call :test_dns_resolution
call :generate_test_report
goto :eof

REM Function to show usage
:show_usage
echo LibTMail Automated Testing Script for Windows
echo.
echo Usage: %~nx0 [options]
echo.
echo Options:
echo   -h, --help     Show this help message
echo   -q, --quick    Run quick tests only
echo   -v, --verbose  Verbose output
echo   --system       Test system requirements only
echo   --services     Test service status only
echo   --network      Test network connectivity only
echo.
goto :eof

REM Main function
:main
set "test_type=all"
set "quick_test=false"

REM Parse command line arguments
if "%1"=="-h" goto show_usage
if "%1"=="--help" goto show_usage
if "%1"=="-q" set "quick_test=true"
if "%1"=="--quick" set "quick_test=true"
if "%1"=="--system" set "test_type=system"
if "%1"=="--services" set "test_type=services"
if "%1"=="--network" set "test_type=network"

call :check_admin

if "%test_type%"=="system" (
    call :init_test_env
    call :test_system_requirements
    call :test_package_installations
) else if "%test_type%"=="services" (
    call :init_test_env
    call :test_service_status
) else if "%test_type%"=="network" (
    call :init_test_env
    call :test_port_availability
    call :test_dns_resolution
) else (
    call :run_all_tests
)

if %FAILED_TESTS% gtr 0 (
    exit /b 1
) else (
    exit /b 0
)
goto :eof

REM Run main function
call :main

endlocal
