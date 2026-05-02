@echo off
REM LibTMail Quick Install Script for Windows
REM One-click installation of LibTMail mail server
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
set "REPO_URL=https://github.com/tda45/LibTMail.git"
set "INSTALL_DIR=C:\temp\LibTMail"
set "TEMP_DIR=C:\temp\libtmail_install"

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
echo  ^|______\___/ \__,_^|\__\__,_^|___/\__^|_^|_^|  
echo               __/ ^|                      
echo              ^|___/     Mail Server       
echo %NC%
echo %GREEN%LibTMail - Windows Mail Server Configuration%NC%
echo %YELLOW%Quick Install Script v1.0%NC%
echo.
goto :eof

REM Function to check if running as administrator
:check_admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "This script must be run as Administrator"
    echo Right-click the script and select "Run as administrator"
    pause
    exit /b 1
)
goto :eof

REM Function to check internet connection
:check_internet
call :print_status "Checking internet connection..."
ping -n 1 google.com >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "No internet connection detected"
    call :print_status "Please check your network connection and try again"
    pause
    exit /b 1
)
call :print_status "Internet connection OK"
goto :eof

REM Function to check system requirements
:check_requirements
call :print_header "Checking System Requirements"

REM Check OS version
for /f "tokens=4-5 delims=. " %%i in ('ver') do set "VERSION=%%i.%%j"
if "%version%" == "10.0" (
    call :print_status "OS: Windows 10/11 ✓"
) else if "%version%" == "6.3" (
    call :print_status "OS: Windows 8.1 ✓"
) else if "%version%" == "6.1" (
    call :print_status "OS: Windows 7 ✓"
) else (
    call :print_warning "OS: Windows %version% (may not be supported)"
)

REM Check architecture
set "ARCH=x64"
if not "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    if not "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
        set "ARCH=x86"
        call :print_warning "Architecture: %ARCH% (x64 recommended)"
    ) else (
        call :print_status "Architecture: x64 ✓"
    )
) else (
    call :print_status "Architecture: x64 ✓"
)

REM Check RAM
for /f "skip=1 delims== tokens=2" %%a in ('wmic computersystem get TotalPhysicalMemory /value') do (
    set /a "RAM=%%a/1024/1024/1024"
    goto :ram_done
)
:ram_done
if %RAM% lss 2 (
    call :print_warning "RAM: %RAM%GB (2GB+ recommended)"
) else (
    call :print_status "RAM: %RAM%GB ✓"
)

REM Check disk space
for /f "tokens=3" %%a in ('dir c:\ ^| find "bytes free"') do (
    set "FREE_SPACE=%%a"
    set "FREE_SPACE=!FREE_SPACE:,=!"
)
set /a "DISK_GB=%FREE_SPACE:~0,-9%"
if %DISK_GB% lss 20 (
    call :print_warning "Disk Space: %DISK_GB%GB (20GB+ recommended)"
) else (
    call :print_status "Disk Space: %DISK_GB%GB ✓"
)

REM Check required commands
set "commands_ok=true"
where git >nul 2>&1
if %errorlevel% neq 0 (
    call :print_warning "git: ✗ (will be installed)"
    set "commands_ok=false"
) else (
    call :print_status "git: ✓"
)

where curl >nul 2>&1
if %errorlevel% neq 0 (
    call :print_warning "curl: ✗ (will be installed)"
    set "commands_ok=false"
) else (
    call :print_status "curl: ✓"
)

where powershell >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "PowerShell: ✗ (required)"
    pause
    exit /b 1
) else (
    call :print_status "PowerShell: ✓"
)

goto :eof

REM Function to install dependencies
:install_dependencies
call :print_header "Installing Dependencies"

REM Install Chocolatey if not present
where choco >nul 2>&1
if %errorlevel% neq 0 (
    call :print_status "Installing Chocolatey..."
    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    if %errorlevel% neq 0 (
        call :print_error "Failed to install Chocolatey"
        pause
        exit /b 1
    )
) else (
    call :print_status "Chocolatey is already installed"
)

REM Install required packages
call :print_status "Installing git and curl..."
choco install git curl --yes
if %errorlevel% neq 0 (
    call :print_error "Failed to install dependencies"
    pause
    exit /b 1
)

call :print_status "Dependencies installed"
goto :eof

REM Function to download LibTMail
:download_libtmail
call :print_header "Downloading LibTMail"

REM Clean up previous downloads
if exist "%INSTALL_DIR%" rmdir /S /Q "%INSTALL_DIR%"
if exist "%TEMP_DIR%" rmdir /S /Q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

REM Download from GitHub
where git >nul 2>&1
if %errorlevel% equ 0 (
    call :print_status "Cloning from GitHub..."
    git clone "%REPO_URL%" "%INSTALL_DIR%"
) else (
    call :print_status "Downloading as ZIP file..."
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/tda45/LibTMail/archive/refs/heads/master.zip' -OutFile '%TEMP_DIR%\LibTMail.zip'"
    powershell -Command "Expand-Archive -Path '%TEMP_DIR%\LibTMail.zip' -DestinationPath '%TEMP_DIR%' -Force"
    move "%TEMP_DIR%\LibTMail-master" "%INSTALL_DIR%"
)

if not exist "%INSTALL_DIR%" (
    call :print_error "Failed to download LibTMail"
    pause
    exit /b 1
)

call :print_status "LibTMail downloaded successfully"
goto :eof

REM Function to verify installation
:verify_installation
call :print_header "Verifying Installation"

set "required_files=config.bat uninstall.bat README.md LICENSE"

for %%f in (%required_files%) do (
    if exist "%INSTALL_DIR%\%%f" (
        call :print_status "%%f: ✓"
    ) else (
        call :print_error "%%f: ✗ (missing)"
        pause
        exit /b 1
    )
)

call :print_status "Installation verified"
goto :eof

REM Function to show installation options
:show_options
call :print_header "Installation Options"

echo Choose installation type:
echo 1) Standard Installation (Interactive)
echo 2) Quick Installation (Default settings)
echo 3) Custom Installation (Advanced)
echo 4) Exit
echo.

:option_loop
set /p "choice=Enter your choice [1-4]: "
if "%choice%"=="1" (
    set "INSTALL_TYPE=standard"
    goto :option_done
) else if "%choice%"=="2" (
    set "INSTALL_TYPE=quick"
    goto :option_done
) else if "%choice%"=="3" (
    set "INSTALL_TYPE=custom"
    goto :option_done
) else if "%choice%"=="4" (
    call :print_status "Installation cancelled"
    pause
    exit /b 0
) else (
    call :print_error "Invalid choice. Please enter 1-4."
    goto :option_loop
)

:option_done
goto :eof

REM Function to run standard installation
:run_standard_install
call :print_header "Starting Standard Installation"

cd /d "%INSTALL_DIR%"
call config.bat
goto :eof

REM Function to run quick installation
:run_quick_install
call :print_header "Starting Quick Installation"

cd /d "%INSTALL_DIR%"

REM Create answers file for non-interactive installation
echo example.com > answers.txt
echo mail >> answers.txt
echo admin@example.com >> answers.txt

REM Run with automated answers
call config.bat < answers.txt

REM Clean up
del answers.txt
goto :eof

REM Function to run custom installation
:run_custom_install
call :print_header "Custom Installation Options"

echo Custom installation allows you to:
echo 1) Skip certain components
echo 2) Use custom paths
echo 3) Modify configuration before installation
echo.

set /p "modify_config=Do you want to modify configuration? (y/N): "
if /i "%modify_config%"=="y" (
    call :print_status "Opening configuration for editing..."
    timeout /t 2 >nul
    
    REM Open config.bat in notepad
    notepad "%INSTALL_DIR%\config.bat"
)

cd /d "%INSTALL_DIR%"
call config.bat
goto :eof

REM Function to show post-installation summary
:show_summary
call :print_header "Installation Summary"

echo %GREEN%LibTMail has been successfully installed on Windows!%NC%
echo.
echo Installation Directory: %INSTALL_DIR%
echo Configuration Script: %INSTALL_DIR%\config.bat
echo Uninstall Script: %INSTALL_DIR%\uninstall.bat
echo.
echo Next Steps:
echo 1. Configure your DNS MX records
echo 2. Test email functionality
echo 3. Set up email clients
echo.
echo Management Commands:
echo   mailadmin.bat     - Manage email users
echo   mailbackup.bat    - Backup mail server
echo.
echo For detailed documentation, see: %INSTALL_DIR%\README.md
echo.
call :print_warning "Save your passwords and configuration securely!"
pause
goto :eof

REM Function to cleanup
:cleanup
call :print_status "Cleaning up temporary files..."
if exist "%TEMP_DIR%" rmdir /S /Q "%TEMP_DIR%"
goto :eof

REM Function to handle errors
:handle_error
call :print_error "Installation failed!"
call :print_status "Check the logs above for error details"
call :print_status "You can try running the installation manually:"
echo   cd /d "%INSTALL_DIR%"
echo   config.bat
call :cleanup
pause
exit /b 1
goto :eof

REM Main function
:main
call :show_banner
call :check_admin
call :check_internet
call :check_requirements
call :install_dependencies
call :download_libtmail
call :verify_installation
call :show_options

if "%INSTALL_TYPE%"=="standard" (
    call :run_standard_install
) else if "%INSTALL_TYPE%"=="quick" (
    call :run_quick_install
) else if "%INSTALL_TYPE%"=="custom" (
    call :run_custom_install
)

call :show_summary
call :cleanup

call :print_status "Quick install completed successfully!"
pause
goto :eof

REM Run main function
call :main

endlocal
