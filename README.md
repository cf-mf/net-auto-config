# Configurador de Rede Automático / Automatic Network Configurator

### NOTA: Este repositório oferece dois scripts idênticos, mas com idiomas diferentes. Escolha o que preferir:

- `network-config.bat` - prompts and comments in **English**

- `configurar-rede.bat` - prompts e comentários em **Português**

---

## 🇺🇸 English

### Description
This Windows `.bat` script automatically configures **IP, DNS, and Proxy** on a network adapter. It allows configuring a network profile and choosing operating modes (automatic or manual).

### Features
- Automatic or manual network adapter selection
- Static IP or DHCP configuration.
- Configure primary and secondary DNS.  
- Enable or disable Proxy.  

### Requirements
- Windows (7, 8, 10, or 11)  
- Run the script as **Administrator**  

### Usage
1. Download or copy the content of `network-config.bat` into Notepad or another text editor.  
2. Optionally, edit the configuration variables at the top of the script:  
   - `NOME_REDE` – network profile label
   - `MODO_AUTO_ADMIN` – auto-elevate to admin (true/false)  
   - `MODO_SELECAO_REDE` – `auto` or `manual`  
   - `MODO_REDE` – `STATIC` or `DHCP`  
   - IP, DNS, and Proxy settings  

3. Run the script and follow on-screen instructions.

### Warnings
- Always backup your current network settings before using.  
- If only one adapter is connected, it will be selected automatically.  
- In automatic IP mode, the current last octet will be reused.
- Do not modify the `.bat` file outside of the configuration variables, it may cause errors

---

## 🇧🇷 Português

### Descrição
Este script `.bat` para Windows permite configurar automaticamente **IP, DNS e Proxy** em um adaptador de rede. Ele permite configurar um perfil de rede e escolher modos de operação (automático ou manual).

### Funcionalidades
- Seleção automática ou manual do adaptador de rede.
- Configuração de IP estático ou DHCP.  
- Configuração de DNS primário e secundário. 
- Ativação ou desativação de Proxy.  

### Pré-requisitos
- Windows (7, 8, 10 ou 11)  
- Executar o script como **Administrador**  

### Como usar
1. Faça download ou copie o conteúdo do `configurar-rede.bat` em um bloco de notas ou outro editor de texto.  
2. Opcionalmente, edite as variáveis de configuração no topo do script:  
   - `NOME_REDE` – etiqueta do perfil de rede
   - `MODO_AUTO_ADMIN` – auto-elevar para administrador (true/false)  
   - `MODO_SELECAO_REDE` – `auto` ou `manual`  
   - `MODO_REDE` – `STATIC` ou `DHCP`  
   - Configurações de IP, DNS e Proxy  

3. Execute o script e siga as instruções na tela.  

### Avisos
- Sempre faça backup das configurações de rede antes de usar.  
- Se houver apenas um adaptador conectado, ele será selecionado automaticamente.  
- No modo automático de IP, o último octeto do IP atual será reaproveitado.
- Não modifique o arquivo `.bat` fora das variáveis de configuração, isso pode causar erros.

---

## 📝 License
[MIT License](LICENSE)
