@echo off
SetLocal EnableExtensions EnableDelayedExpansion

:: -----------------------------------------------------------------
:: NETWORK CONFIGURATION
:: -----------------------------------------------------------------
:: Edit the variables below to match your network.
:: Do not use spaces before or after the = sign

:: Network profile name (just a label for this script)
SET "NETWORK_NAME=My Corporate Network"

:: Administrator Mode
:: 'true'  = Reopens the script with administrator permissions.
:: 'false' = If not admin, shows a warning and exits.
SET "AUTO_ADMIN_MODE=false"

:: Network Selection Mode
:: 'auto'   = Takes the first "Connected" adapter found.
:: 'manual' = Lists all network adapters and asks which to use.
SET "NETWORK_SELECTION_MODE=auto"

:: Network Mode
:: 'STATIC' = Uses the static IP settings below.
:: 'DHCP'   = Ignores IP settings and uses DHCP.
SET "NETWORK_MODE=STATIC"

:: --- Static IP Configuration (ignored if NETWORK_MODE=DHCP) ---
SET "IP_PREFIX=192.168.8."
SET "IP_SUBNET=255.255.255.0"
SET "IP_GATEWAY=192.168.8.2"

:: --- DNS Configuration (ignored if NETWORK_MODE=DHCP) ---
SET "DNS1=192.168.8.2"
SET "DNS2=192.168.8.3" :: Leave blank (e.g., SET "DNS2=") if no secondary DNS

:: --- Proxy Settings (applied in BOTH modes) ---
:: 'true'  = Enables proxy.
:: 'false' = Disables proxy.
SET "PROXY_ENABLE=true"
SET "PROXY_SERVER=192.168.8.2:3128" :: (ignored if PROXY_ENABLE=false)

:: -----------------------------------------------------------------
:: END OF CONFIGURATION
:: -----------------------------------------------------------------
:: Do not edit below this line.
:: -----------------------------------------------------------------


rem --- 1. Admin Check Logic ---
if /i "%AUTO_ADMIN_MODE%"=="true" (
    goto :AutoAdmin
) else (
    goto :ManualCheck
)

:AutoAdmin
rem Attempts to gain admin privileges automatically
set "params=%*"
cd /d "%~dp0"
%SystemRoot%\System32\fsutil.exe dirty query %systemdrive% 1>nul 2>nul || (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && ""%~s0"" %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs"
    exit /B
)
goto :StartScript

:ManualCheck
rem Only checks if already admin and fails if not
%SystemRoot%\System32\net.exe session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ERROR: This script must be run as Administrator.
    echo Right-click the file and select "Run as administrator".
    echo.
    pause
    goto :eof
)
goto :StartScript


rem --- 2. Start Script Logic ---
:StartScript
echo Configuring network profile: %NETWORK_NAME%
echo.

rem --- 3. Detect network adapter ---
if /i "%NETWORK_SELECTION_MODE%"=="auto" (
    goto :DetectAuto
) else (
    goto :DetectManual
)

:DetectAuto
echo Detecting network adapter (automatic mode)...
for /f "tokens=4*" %%a in ('%SystemRoot%\System32\netsh.exe interface show interface ^| %SystemRoot%\System32\findstr.exe "Conectado Connected"') do (
  set "ADAPTER_NAME=%%a %%b"
  goto :AdapterFound
)
echo ERROR: No 'Connected' network adapter was found.
echo Check your network cable or Wi-Fi connection.
pause
goto :eof

:DetectManual
echo Detecting connected adapters (manual mode)...
echo.
set "Counter=0"
for /f "tokens=4*" %%a in ('%SystemRoot%\System32\netsh.exe interface show interface ^| %SystemRoot%\System32\findstr.exe "Conectado Connected"') do (
    set /A Counter+=1
    set "ADAPTER_!Counter!=%%a %%b"
    echo !Counter!. %%a %%b
)
echo.
if !Counter! == 0 (
    echo ERROR: No 'Connected' network adapter was found.
    pause
    goto :eof
)
if !Counter! == 1 (
    echo Only 1 adapter found, selecting automatically.
    set "ADAPTER_NAME=!ADAPTER_1!"
    goto :AdapterFound
)

:ChooseAdapter
set "CHOICE="
set /p "CHOICE=Enter the number of the adapter you want to configure (1-!Counter!): "

rem --- Security and Range Validation ---
echo "!CHOICE!" | %SystemRoot%\System32\findstr.exe /R "[^0-9]" >nul
if %errorlevel% equ 0 (
    echo ERROR: Invalid input. Only numbers are allowed.
    goto :ChooseAdapter
)
if "!CHOICE!"=="" (
    echo ERROR: Invalid input. Enter a number.
    goto :ChooseAdapter
)
if !CHOICE! GTR !Counter! (
    echo ERROR: Number too high.
    goto :ChooseAdapter
)
if !CHOICE! LSS 1 (
    echo ERROR: Number too low.
    goto :ChooseAdapter
)

rem --- Map choice to adapter name ---
set "ADAPTER_NAME=!ADAPTER_%CHOICE%!"

:AdapterFound
echo --------------------------------------------------
echo Selected adapter: !ADAPTER_NAME!
echo --------------------------------------------------
echo.

rem --- 4. Apply Network Settings (IP and DNS) ---
if /i "%NETWORK_MODE%"=="DHCP" (
    goto :Apply_DHCP
) else (
    goto :Prepare_STATIC
)

:Apply_DHCP
echo Configuring !ADAPTER_NAME! for DHCP...
%SystemRoot%\System32\netsh.exe interface ip set address name="!ADAPTER_NAME!" source=dhcp
%SystemRoot%\System32\netsh.exe interface ip set dnsservers name="!ADAPTER_NAME!" source=dhcp
echo IP and DNS set to DHCP.
goto :Apply_Proxy

:Prepare_STATIC
rem --- IP Logic Block ---
echo Detecting current IP...
set "CURRENT_IP_OCTET=not_found"

rem Search for current IP to get last octet
for /f "tokens=3" %%I in ('%SystemRoot%\System32\netsh.exe interface IPv4 show addresses "!ADAPTER_NAME!" ^| %SystemRoot%\System32\findstr.exe /R /C:"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  set "CURRENT_IP=%%I"
  goto :IPFound
)
goto :IPNotFound

:IPFound
rem Extract last octet from found IP
for /f "tokens=4 delims=." %%i in ("!CURRENT_IP!") do set "CURRENT_IP_OCTET=%%i"
echo Current IP found: !CURRENT_IP! (Last octet: !CURRENT_IP_OCTET!)

:IPNotFound
if "!CURRENT_IP_OCTET!"=="not_found" (
    echo Warning: Unable to detect current IP.
)
echo.
set /p "_ip_mode=Do you want to set the IP last octet manually? (y/n) [y=manual, n=automatic] "

if /i "%_ip_mode%"=="y" (
    goto :GetIPManual
) else (
    goto :SetIPAutomatic
)

:GetIPManual
rem --- SECURITY VALIDATION ---
set "MANUAL_IP_OCTET="
set /p "MANUAL_IP_OCTET=Enter the last octet of the IP (numbers only): %IP_PREFIX%"

rem Check for non-numeric input
echo "!MANUAL_IP_OCTET!" | %SystemRoot%\System32\findstr.exe /R "[^0-9]" >nul
if %errorlevel% equ 0 (
    echo.
    echo ERROR: Invalid input. Only numbers 0-9 are allowed.
    echo Try again.
    echo.
    goto :GetIPManual
)

rem Check if empty
if "!MANUAL_IP_OCTET!"=="" (
    echo.
    echo ERROR: Input cannot be empty.
    echo Try again.
    echo.
    goto :GetIPManual
)

set "FINAL_IP=%IP_PREFIX%!MANUAL_IP_OCTET!"
goto :Apply_STATIC

:SetIPAutomatic
if "!CURRENT_IP_OCTET!"=="not_found" (
    echo ERROR: Automatic mode failed because no current IP was detected.
    echo Please run again and choose manual mode 'y'.
    pause
    goto :eof
)
echo Using automatic IP last octet: !CURRENT_IP_OCTET!
set "FINAL_IP=%IP_PREFIX%!CURRENT_IP_OCTET!"
goto :Apply_STATIC

:Apply_STATIC
echo Applying Static IP: !FINAL_IP!...
%SystemRoot%\System32\netsh.exe interface ip set address name="!ADAPTER_NAME!" source=static !FINAL_IP! %IP_SUBNET% %IP_GATEWAY% 1

echo Applying Primary DNS: %DNS1%...
%SystemRoot%\System32\netsh.exe interface ip set dnsservers name="!ADAPTER_NAME!" source=static %DNS1% primary validate=no

if NOT "%DNS2%"=="" (
    echo Applying Secondary DNS: %DNS2%...
    %SystemRoot%\System32\netsh.exe interface ipv4 add dnsserver name="!ADAPTER_NAME!" address=%DNS2% index=2 validate=no
)
echo Static IP and DNS applied.
goto :Apply_Proxy


rem --- 5. Apply Proxy Settings ---
:Apply_Proxy
echo.
if /i "%PROXY_ENABLE%"=="true" (
    echo Enabling Proxy: %PROXY_SERVER%...
    %SystemRoot%\System32\reg.exe ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f
    %SystemRoot%\System32\reg.exe ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "%PROXY_SERVER%" /f
) else (
    echo Disabling Proxy...
    %SystemRoot%\System32\reg.exe ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f
)
echo Proxy configuration applied.
goto :EndScript


rem --- 6. Conclusion ---
:EndScript
echo.
echo --------------------------------------------------
echo Network configuration '%NETWORK_NAME%' applied!
echo --------------------------------------------------
echo.
echo Press any key to exit...
pause >nul
goto :eof

:eof
EndLocal
exit /B
