@echo off
SetLocal EnableExtensions EnableDelayedExpansion

:: -----------------------------------------------------------------
:: CONFIGURACAO DA REDE
:: -----------------------------------------------------------------
:: Edite as variaveis abaixo para corresponder a sua rede.
:: Nao use espacos antes ou depois do sinal de =

:: Nome do perfil de rede (apenas uma etiqueta para esse script)
SET "NOME_REDE=Minha Rede Corporativa"

:: Modo de Administrador
:: 'true'  = Abre o script novamente com permissoes de administrador.
:: 'false' = Se nao for administrador, mostra um aviso e encerra.
SET "MODO_AUTO_ADMIN=false"

:: Modo de Selecao de Rede
:: 'auto'   = Pega o primeiro adaptador "Conectado" que encontrar.
:: 'manual' = Lista todos os adaptadores de rede e pergunta qual usar.
SET "MODO_SELECAO_REDE=auto"

:: Modo de Rede
:: 'STATIC' = Usa as configuracoes de IP estatico abaixo.
:: 'DHCP'   = Ignora as configuracoes de IP e usa DHCP.
SET "MODO_REDE=STATIC"

:: --- Configuracoes de IP Estatico (ignorado se MODO_REDE=DHCP) ---
SET "IP_PREFIX=192.168.8."
SET "IP_SUBNET=255.255.255.0"
SET "IP_GATEWAY=192.168.8.2"

:: --- Configuracoes de DNS (ignorado se MODO_REDE=DHCP) ---
SET "DNS1=192.168.8.2"
SET "DNS2=192.168.8.3" :: Deixe em branco (ex: SET "DNS2=") se nao houver DNS secundario

:: --- Configuracoes de Proxy (aplicado em AMBOS os modos) ---
:: 'true'  = Ativa o proxy.
:: 'false' = Desativa o proxy.
SET "PROXY_ENABLE=true"
SET "PROXY_SERVER=192.168.8.2:3128" :: (ignorado se PROXY_ENABLE=false)

:: -----------------------------------------------------------------
:: FIM DA CONFIGURACAO
:: -----------------------------------------------------------------
:: Nao edite abaixo desta linha.
:: -----------------------------------------------------------------


rem --- 1. Logica de Verificacao de Administrador ---
if /i "%MODO_AUTO_ADMIN%"=="true" (
    goto :AutoAdmin
) else (
    goto :VerificacaoManual
)

:AutoAdmin
rem Tenta obter privilegios de ADM automaticamente
set "params=%*"
cd /d "%~dp0"
%SystemRoot%\System32\fsutil.exe dirty query %systemdrive% 1>nul 2>nul || (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && ""%~s0"" %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs"
    exit /B
)
goto :InicioScript

:VerificacaoManual
rem Apenas verifica se ja e ADM e falha se nao for
%SystemRoot%\System32\net.exe session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ERRO: Este script precisa ser executado como Administrador.
    echo Clique com o botao direito no arquivo e "Executar como administrador".
    echo.
    pause
    goto :eof
)
goto :InicioScript


rem --- 2. Inicio da Logica do Script ---
:InicioScript
echo Configurando perfil de rede: %NOME_REDE%
echo.

rem --- 3. Detectar adaptador de rede ---
if /i "%MODO_SELECAO_REDE%"=="auto" (
    goto :DetectarAuto
) else (
    goto :DetectarManual
)

:DetectarAuto
echo Detectando adaptador de rede (modo automatico)...
for /f "tokens=4*" %%a in ('%SystemRoot%\System32\netsh.exe interface show interface ^| %SystemRoot%\System32\findstr.exe "Conectado Connected"') do (
  set "ADAPTADOR_NOME=%%a %%b"
  goto :AdaptadorEncontrado
)
echo ERRO: Nenhum adaptador de rede 'Conectado' foi encontrado.
echo Verifique seu cabo de rede ou conexao Wi-Fi.
pause
goto :eof

:DetectarManual
echo Detectando adaptadores conectados (modo manual)...
echo.
set "Contador=0"
for /f "tokens=4*" %%a in ('%SystemRoot%\System32\netsh.exe interface show interface ^| %SystemRoot%\System32\findstr.exe "Conectado Connected"') do (
    set /A Contador+=1
    set "ADAPTADOR_!Contador!=%%a %%b"
    echo !Contador!. %%a %%b
)
echo.
if !Contador! == 0 (
    echo ERRO: Nenhum adaptador de rede 'Conectado' foi encontrado.
    pause
    goto :eof
)
if !Contador! == 1 (
    echo Apenas 1 adaptador encontrado, selecionando automaticamente.
    set "ADAPTADOR_NOME=!ADAPTADOR_1!"
    goto :AdaptadorEncontrado
)

:EscolherAdaptador
set "ESCOLHA="
set /p "ESCOLHA=Digite o numero do adaptador que deseja configurar (1-!Contador!): "

rem --- Validacao de Seguranca e de Range ---
echo "!ESCOLHA!" | %SystemRoot%\System32\findstr.exe /R "[^0-9]" >nul
if %errorlevel% equ 0 (
    echo ERRO: Entrada invalida. Apenas numeros sao permitidos.
    goto :EscolherAdaptador
)
if "!ESCOLHA!"=="" (
    echo ERRO: Entrada invalida. Digite um numero.
    goto :EscolherAdaptador
)
if !ESCOLHA! GTR !Contador! (
    echo ERRO: Numero muito alto.
    goto :EscolherAdaptador
)
if !ESCOLHA! LSS 1 (
    echo ERRO: Numero muito baixo.
    goto :EscolherAdaptador
)

rem --- Mapeia a escolha para o nome do adaptador ---
set "ADAPTADOR_NOME=!ADAPTADOR_%ESCOLHA%!"

:AdaptadorEncontrado
echo --------------------------------------------------
echo Adaptador selecionado: !ADAPTADOR_NOME!
echo --------------------------------------------------
echo.

rem --- 4. Aplicar Configuracoes de Rede (IP e DNS) ---
if /i "%MODO_REDE%"=="DHCP" (
    goto :Aplicar_DHCP
) else (
    goto :Preparar_STATIC
)

:Aplicar_DHCP
echo Configurando !ADAPTADOR_NOME! para DHCP...
%SystemRoot%\System32\netsh.exe interface ip set address name="!ADAPTADOR_NOME!" source=dhcp
%SystemRoot%\System32\netsh.exe interface ip set dnsservers name="!ADAPTADOR_NOME!" source=dhcp
echo IP e DNS configurados para DHCP.
goto :Aplicar_Proxy

:Preparar_STATIC
rem --- Bloco de Logica de IP ---
echo Detectando IP atual...
set "IP_OCTETO_ATUAL=nao_encontrado"

rem Procura pelo IP atual para pegar o ultimo octeto
for /f "tokens=3" %%I in ('%SystemRoot%\System32\netsh.exe interface IPv4 show addresses "!ADAPTADOR_NOME!" ^| %SystemRoot%\System32\findstr.exe /R /C:"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  set "IP_ATUAL=%%I"
  goto :IPEncontrado
)
goto :IPNaoEncontrado

:IPEncontrado
rem Extrai o ultimo octeto do IP encontrado
for /f "tokens=4 delims=." %%i in ("!IP_ATUAL!") do set "IP_OCTETO_ATUAL=%%i"
echo IP atual encontrado: !IP_ATUAL! (Final: !IP_OCTETO_ATUAL!)

:IPNaoEncontrado
if "!IP_OCTETO_ATUAL!"=="nao_encontrado" (
    echo Aviso: Nao foi possivel detectar o IP atual.
)
echo.
set /p "_modo_ip=Quer configurar o final do IP manualmente? (s/n) [s=manual, n=automatico] "

if /i "%_modo_ip%"=="s" (
    goto :ObterIPManual
) else (
    goto :DefinirIPAutomatico
)

:ObterIPManual
rem --- VALIDACAO DE SEGURANCA ---
set "IP_OCTETO_MANUAL="
set /p "IP_OCTETO_MANUAL=Digite o final do IP (apenas numeros): %IP_PREFIX%"

rem Verifica se a entrada contem algo que NAO seja um numero
echo "!IP_OCTETO_MANUAL!" | %SystemRoot%\System32\findstr.exe /R "[^0-9]" >nul
if %errorlevel% equ 0 (
    echo.
    echo ERRO: Entrada invalida. Apenas numeros de 0 a 9 sao permitidos.
    echo Tente novamente.
    echo.
    goto :ObterIPManual
)

rem Verifica se esta vazio
if "!IP_OCTETO_MANUAL!"=="" (
    echo.
    echo ERRO: A entrada nao pode ser vazia.
    echo Tente novamente.
    echo.
    goto :ObterIPManual
)

set "IP_FINAL=%IP_PREFIX%!IP_OCTETO_MANUAL!"
goto :Aplicar_STATIC

:DefinirIPAutomatico
if "!IP_OCTETO_ATUAL!"=="nao_encontrado" (
    echo ERRO: Modo automatico falhou pois nenhum IP atual foi detectado.
    echo Por favor, execute novamente e escolha o modo manual 's'.
    pause
    goto :eof
)
echo Usando final de IP automatico: !IP_OCTETO_ATUAL!
set "IP_FINAL=%IP_PREFIX%!IP_OCTETO_ATUAL!"
goto :Aplicar_STATIC

:Aplicar_STATIC
echo Aplicando IP Estatico: !IP_FINAL!...
%SystemRoot%\System32\netsh.exe interface ip set address name="!ADAPTADOR_NOME!" source=static !IP_FINAL! %IP_SUBNET% %IP_GATEWAY% 1

echo Aplicando DNS Primario: %DNS1%...
%SystemRoot%\System32\netsh.exe interface ip set dnsservers name="!ADAPTADOR_NOME!" source=static %DNS1% primary validate=no

if NOT "%DNS2%"=="" (
    echo Aplicando DNS Secundario: %DNS2%...
    %SystemRoot%\System32\netsh.exe interface ipv4 add dnsserver name="!ADAPTADOR_NOME!" address=%DNS2% index=2 validate=no
)
echo IP e DNS Estaticos aplicados.
goto :Aplicar_Proxy


rem --- 5. Aplicar Configuracoes de Proxy ---
:Aplicar_Proxy
echo.
if /i "%PROXY_ENABLE%"=="true" (
    echo Ativando Proxy: %PROXY_SERVER%...
    %SystemRoot%\System32\reg.exe ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f
    %SystemRoot%\System32\reg.exe ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "%PROXY_SERVER%" /f
) else (
    echo Desativando Proxy...
    %SystemRoot%\System32\reg.exe ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f
)
echo Configuracao de proxy aplicada.
goto :FimScript


rem --- 6. Conclusao ---
:FimScript
echo.
echo --------------------------------------------------
echo Configuracao de rede '%NOME_REDE%' foi aplicada!
echo --------------------------------------------------
echo.
echo Pressione qualquer tecla para sair...
pause >nul
goto :eof

:eof
EndLocal
exit /B