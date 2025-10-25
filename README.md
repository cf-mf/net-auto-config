# Automatic Network Configurator / Configurador de Rede Automático

## 🇺🇸 English

### Description
This Windows `.bat` script automatically configures **IP, DNS, and Proxy** on a network adapter. It supports multiple network profiles and operating modes (automatic or manual).

### Features
- Automatic network adapter detection or manual selection.  
- Set static IP or DHCP.  
- Configure primary and secondary DNS.  
- Enable or disable Proxy.  
- Supports multiple network profiles via the `NOME_REDE` variable.

### Requirements
- Windows (7, 8, 10, or 11)  
- Run the script as **Administrator**  
- Original `.bat` file should not be modified outside the configuration variables

### Usage
1. Open `network-config.bat` with Notepad or another text editor..  
2. Edit the configuration variables at the top of the script (optional):  
   - `NOME_REDE` – profile label  
   - `MODO_AUTO_ADMIN` – auto-elevate to admin (true/false)  
   - `MODO_SELECAO_REDE` – `auto` or `manual`  
   - `MODO_REDE` – `STATIC` or `DHCP`  
   - IP, DNS, and Proxy settings  

3. Run the script and follow on-screen instructions.

### Warnings
- Always backup your current network settings before using.  
- If only one adapter is connected, it will be selected automatically.  
- In automatic IP mode, the current last octet will be reused.

---

## 🇧🇷 Português

### Descrição
Este script `.bat` para Windows permite configurar automaticamente **IP, DNS e Proxy** em um adaptador de rede. Ele suporta múltiplos perfis de rede e modos de operação (automático ou manual).

### Funcionalidades
- Seleção automática do adaptador de rede ou escolha manual.  
- Configuração de IP estático ou DHCP.  
- Aplicação de DNS primário e secundário.  
- Ativação ou desativação de Proxy.  
- Suporte para múltiplos perfis de rede via variável `NOME_REDE`.

### Pré-requisitos
- Windows (7, 8, 10 ou 11)  
- Executar o script como **Administrador**  
- Arquivo `.bat` original não deve ser alterado fora das variáveis de configuração

### Como usar
1. Abra o arquivo `network-config.bat` com o bloco de notas ou outro editor de texto.  
2. Edite as variáveis de configuração no topo do script:  
   - `NOME_REDE` – etiqueta do perfil de rede
   - `MODO_AUTO_ADMIN` – auto-elevar para administrador (true/false)  
   - `MODO_SELECAO_REDE` – `auto` ou `manual`  
   - `MODO_REDE` – `STATIC` ou `DHCP`  
   - Configurações de IP, DNS e Proxy  

3. Execute o script e siga as instruções na tela.  

### Avisos
- Sempre faça backup das configurações atuais de rede antes de usar.  
- Se houver apenas um adaptador conectado, ele será selecionado automaticamente.  
- No modo automático de IP, o último octeto do IP atual será reaproveitado.

---

## 📝 License
[MIT License](LICENSE)
