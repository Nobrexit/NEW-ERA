#!/bin/bash
# ====================================================================
#                  ✨ NEW ERA PROXY MANAGER - v1.0.0 ✨
# ====================================================================

PORTS_FILE="/opt/neweraproxy/ports"
CONFIG_DIR="/etc/neweraproxy"

# Cores
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"
WHITE_BG="\033[47;1;30m"

# Verificar privilégios de root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Por favor, execute este script como root ou com sudo.${RESET}"
  exit 1
fi

# Garantir estrutura de pastas
mkdir -p /opt/neweraproxy
mkdir -p "$CONFIG_DIR"
touch "$PORTS_FILE"

is_port_in_use() {
    local port=$1
    if netstat -tuln 2>/dev/null | awk '{print $4}' | grep -q ":$port$"; then
        return 0
    elif ss -tuln 2>/dev/null | awk '{print $4}' | grep -q ":$port$"; then
        return 0
    elif lsof -i :"$port" 2>/dev/null | grep -q LISTEN; then
        return 0
    else
        return 1
    fi
}

add_proxy_port() {
    clear
    echo -e "${BLUE}==============================================================${RESET}"
    echo -e "${CYAN}                  🚀 ATIVAR NOVO PROXY                         ${RESET}"
    echo -e "${BLUE}==============================================================${RESET}"
    echo ""

    read -p "  PORTA DO PROXY (Ex: 80, 443, 8080): " port
    while ! [[ $port =~ ^[0-9]+$ ]]; do
        echo -e "  ${RED}❌ Digite uma porta válida!${RESET}"
        read -p "  PORTA DO PROXY: " port
    done

    # Verificar se a porta já está cadastrada ou em uso
    if grep -q "^$port|" "$PORTS_FILE"; then
        echo -e "\n${RED}⛔️ Esta porta já está cadastrada no NEW ERA PROXY!${RESET}"
        read -n 1 -s -r -p "Pressione qualquer tecla para voltar."
        return
    fi

    if is_port_in_use "$port"; then
        echo -e "\n${YELLOW}⚠️ Atenção: A porta $port já parece estar em uso por outro serviço!${RESET}"
        read -p "  Deseja tentar ativar mesmo assim? (s/n): " force_port
        if [[ "$force_port" != "s" && "$force_port" != "S" ]]; then
            return
        fi
    fi

    echo -e "\n  🔒 ATIVAR CRIPTOGRAFIA SSL/TLS (PORTA 443)?"
    read -p "  [s] Sim | [n] Não (padrão): " ssl_opt
    local ssl="false"
    if [[ "$ssl_opt" == "s" || "$ssl_opt" == "S" ]]; then
        ssl="true"
    fi

    read -p "  MENSAGEM DE STATUS (Padrão: NEW ERA PROXY): " status
    if [ -z "$status" ]; then
        status="NEW ERA PROXY"
    fi

    read -p "  PORTA SSH LOCAL (Padrão: 22): " ssh_port
    if [ -z "$ssh_port" ]; then
        ssh_port="22"
    fi

    read -p "  PORTA OPENVPN LOCAL (Padrão: 1194): " vpn_port
    if [ -z "$vpn_port" ]; then
        vpn_port="1194"
    fi

    read -p "  WEBSOCKET PATH OPCIONAL (Ex: /ws, deixe em branco para nenhum): " ws_path
    read -p "  RESPOSTA CUSTOMIZADA OPCIONAL (Deixe em branco para handshake padrão): " custom_resp

    # Montando comando para o Systemd
    local command="/opt/neweraproxy/proxy --port $port --status \"$status\" --ssh-port $ssh_port --vpn-port $vpn_port"
    if [ "$ssl" == "true" ]; then
        command="$command --ssl --ssl-cert $CONFIG_DIR/cert.pem --ssl-key $CONFIG_DIR/key.pem"
    fi
    if [ -n "$ws_path" ]; then
        command="$command --ws-path \"$ws_path\""
    fi
    if [ -n "$custom_resp" ]; then
        command="$command --custom-response \"$custom_resp\""
    fi

    local service_file_path="/etc/systemd/system/neweraproxy_${port}.service"
    local service_file_content="[Unit]
Description=NEW ERA PROXY - Porta ${port}
After=network.target

[Service]
LimitNOFILE=65535
Type=simple
ExecStart=${command}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target"

    echo "$service_file_content" > "$service_file_path"
    
    systemctl daemon-reload
    systemctl enable "neweraproxy_${port}.service" >/dev/null 2>&1
    systemctl start "neweraproxy_${port}.service" >/dev/null 2>&1

    # Verificar se iniciou com sucesso
    sleep 1.5
    if systemctl is-active --quiet "neweraproxy_${port}.service"; then
        # Salva registro no arquivo de portas
        echo "$port|$ssl|$status|$ssh_port|$vpn_port|$ws_path|$custom_resp" >> "$PORTS_FILE"
        echo -e "\n${GREEN}✅ NEW ERA PROXY ATIVADO COM SUCESSO NA PORTA $port!${RESET}"
    else
        echo -e "\n${RED}❌ Ocorreu um erro ao iniciar o serviço na porta $port.${RESET}"
        echo -e "${YELLOW}Dica: Verifique se os certificados existem ou consulte os logs usando a opção 6.${RESET}"
        systemctl stop "neweraproxy_${port}.service" >/dev/null 2>&1
        rm -f "$service_file_path"
        systemctl daemon-reload
    fi

    sleep 2
}

del_proxy_port() {
    clear
    echo -e "${BLUE}==============================================================${RESET}"
    echo -e "${RED}                  🗑️ DESATIVAR PROXY                           ${RESET}"
    echo -e "${BLUE}==============================================================${RESET}"
    echo ""

    if [ ! -s "$PORTS_FILE" ]; then
        echo -e "  ${YELLOW}Nenhum proxy ativo encontrado para remover.${RESET}"
        sleep 2
        return
    fi

    echo -e "  Selecione a porta que deseja fechar:"
    local i=1
    local ports_array=()
    while IFS='|' read -r port ssl status ssh_port vpn_port ws_path custom_resp; do
        ports_array+=("$port")
        local ssl_badge="${RED}Sem SSL${RESET}"
        if [ "$ssl" == "true" ]; then
            ssl_badge="${GREEN}Com SSL (443)${RESET}"
        fi
        echo -e "  ${CYAN}[$i]${RESET} Porta: ${YELLOW}$port${RESET} ($ssl_badge) | Status: $status"
        i=$((i+1))
    done < "$PORTS_FILE"

    echo ""
    read -p "  Escolha o número ou digite a porta diretamente: " choice

    local selected_port=""
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        if [ "$choice" -lt "$i" ] && [ "$choice" -gt 0 ]; then
            selected_port="${ports_array[$((choice-1))]}"
        else
            selected_port="$choice"
        fi
    fi

    if [ -z "$selected_port" ] || ! grep -q "^$selected_port|" "$PORTS_FILE"; then
        echo -e "\n  ${RED}❌ Porta inválida ou não cadastrada!${RESET}"
        sleep 2
        return
    fi

    echo -e "\n  ${YELLOW}Removendo proxy da porta $selected_port...${RESET}"
    
    systemctl stop "neweraproxy_${selected_port}.service" >/dev/null 2>&1
    systemctl disable "neweraproxy_${selected_port}.service" >/dev/null 2>&1
    rm -f "/etc/systemd/system/neweraproxy_${selected_port}.service"
    systemctl daemon-reload

    # Encerrar qualquer processo teimoso
    if lsof -i :"$selected_port" &>/dev/null; then
        fuser -k "$selected_port"/tcp >/dev/null 2>&1
    fi

    # Remover do arquivo de configuração
    sed -i "/^$selected_port|/d" "$PORTS_FILE"

    echo -e "${GREEN}✅ Proxy da porta $selected_port desativado e removido!${RESET}"
    sleep 2
}

restart_all_proxies() {
    clear
    echo -e "${BLUE}==============================================================${RESET}"
    echo -e "${YELLOW}                  🔃 REINICIAR PROXIES                         ${RESET}"
    echo -e "${BLUE}==============================================================${RESET}"
    echo ""

    if [ ! -s "$PORTS_FILE" ]; then
        echo -e "  ${YELLOW}Nenhum proxy cadastrado para reiniciar.${RESET}"
        sleep 2
        return
    fi

    echo -e "  Reiniciando todos os serviços do NEW ERA PROXY..."
    
    while IFS='|' read -r port ssl status ssh_port vpn_port ws_path custom_resp; do
        echo -e "  🔄 Reiniciando porta ${YELLOW}$port${RESET}..."
        systemctl restart "neweraproxy_${port}.service" >/dev/null 2>&1
    done < "$PORTS_FILE"

    echo -e "\n${GREEN}✅ Todos os proxies foram reiniciados com sucesso!${RESET}"
    sleep 2
}

setup_certbot_ssl() {
    clear
    echo -e "${BLUE}==============================================================${RESET}"
    echo -e "${MAGENTA}              📜 CONFIGURAR CERTIFICADO LET'S ENCRYPT         ${RESET}"
    echo -e "${BLUE}==============================================================${RESET}"
    echo ""
    echo -e "  Este assistente configura um certificado SSL/TLS oficial e"
    echo -e "  gratuito da Let's Encrypt para o seu domínio usando o Certbot."
    echo -e "  Garante conexões 100% seguras na porta 443 sem alertas SSL!"
    echo ""
    echo -e "  ${RED}Requisitos:${RESET}"
    echo -e "  1. Seu domínio deve estar apontado para o IP deste VPS."
    echo -e "  2. A porta 80 deve estar livre temporariamente."
    echo ""

    read -p "  Deseja prosseguir? (s/n): " confirm
    if [[ "$force_port" != "s" && "$force_port" != "S" && "$confirm" != "s" && "$confirm" != "S" ]]; then
        return
    fi

    read -p "  Digite o seu domínio (Ex: proxy.meudominio.com): " domain
    if [ -z "$domain" ]; then
        echo -e "\n  ${RED}❌ Domínio inválido!${RESET}"
        sleep 2
        return
    fi

    # Verificar certbot
    if ! command -v certbot &> /dev/null; then
        echo -e "\n  ${YELLOW}Instalando Certbot no sistema...${RESET}"
        apt-get update > /dev/null 2>&1
        apt-get install certbot -y > /dev/null 2>&1
    fi

    echo -e "\n  ${YELLOW}Liberando porta 80 temporariamente...${RESET}"
    # Stop any proxy on port 80 if active
    local stop_p80="false"
    if grep -q "^80|" "$PORTS_FILE"; then
        systemctl stop neweraproxy_80.service >/dev/null 2>&1
        stop_p80="true"
    fi
    # Also stop system nginx/apache if any
    systemctl stop nginx >/dev/null 2>&1
    systemctl stop apache2 >/dev/null 2>&1

    echo -e "  ${YELLOW}Solicitando certificado oficial para $domain...${RESET}"
    certbot certonly --standalone --non-interactive --agree-tos --register-unsafely-without-email -d "$domain"
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e "\n  ${GREEN}✅ Certificado gerado com sucesso!${RESET}"
        echo -e "  ${YELLOW}Vinculando ao NEW ERA PROXY...${RESET}"
        
        rm -f "$CONFIG_DIR/cert.pem"
        rm -f "$CONFIG_DIR/key.pem"
        
        ln -sf "/etc/letsencrypt/live/$domain/fullchain.pem" "$CONFIG_DIR/cert.pem"
        ln -sf "/etc/letsencrypt/live/$domain/privkey.pem" "$CONFIG_DIR/key.pem"

        echo -e "  ${GREEN}Certificados instalados em $CONFIG_DIR/!${RESET}"
        
        # Restart all SSL enabled proxies
        while IFS='|' read -r port ssl status ssh_port vpn_port ws_path custom_resp; do
            if [ "$ssl" == "true" ]; then
                echo -e "  🔄 Recarregando serviço na porta SSL ${YELLOW}$port${RESET}..."
                systemctl restart "neweraproxy_${port}.service" >/dev/null 2>&1
            fi
        done < "$PORTS_FILE"
    else
        echo -e "\n  ${RED}❌ Falha ao gerar certificado Let's Encrypt.${RESET}"
        echo -e "  Verifique os registros de DNS de seu domínio e se o IP do VPS está correto."
    fi

    # Restaura porta 80 se necessário
    if [ "$stop_p80" == "true" ]; then
        systemctl start neweraproxy_80.service >/dev/null 2>&1
    fi

    echo ""
    read -n 1 -s -r -p "Pressione qualquer tecla para retornar ao menu."
}

view_logs() {
    clear
    echo -e "${BLUE}==============================================================${RESET}"
    echo -e "${CYAN}                  📋 VISUALIZAR LOGS EM TEMPO REAL             ${RESET}"
    echo -e "${BLUE}==============================================================${RESET}"
    echo ""

    if [ ! -s "$PORTS_FILE" ]; then
        echo -e "  ${YELLOW}Nenhum proxy cadastrado para visualizar logs.${RESET}"
        sleep 2
        return
    fi

    echo -e "  Selecione a porta para acompanhar os logs:"
    local i=1
    local ports_array=()
    while IFS='|' read -r port ssl status ssh_port vpn_port ws_path custom_resp; do
        ports_array+=("$port")
        echo -e "  ${CYAN}[$i]${RESET} Porta: ${YELLOW}$port${RESET} | Status: $status"
        i=$((i+1))
    done < "$PORTS_FILE"

    echo ""
    read -p "  Escolha a opção: " choice

    local selected_port=""
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        if [ "$choice" -lt "$i" ] && [ "$choice" -gt 0 ]; then
            selected_port="${ports_array[$((choice-1))]}"
        fi
    fi

    if [ -z "$selected_port" ]; then
        echo -e "\n  ${RED}❌ Opção inválida!${RESET}"
        sleep 2
        return
    fi

    clear
    echo -e "${GREEN}Acompanhando logs em tempo real para a porta $selected_port...${RESET}"
    echo -e "${YELLOW}Pressione Ctrl+C para voltar ao menu principal.${RESET}"
    echo ""
    journalctl -u "neweraproxy_${selected_port}.service" -f -n 50
}

uninstall_newera() {
    clear
    echo -e "${RED}==============================================================${RESET}"
    echo -e "${RED}                  🗑️ DESINSTALAR NEW ERA PROXY                ${RESET}"
    echo -e "${RED}==============================================================${RESET}"
    echo ""
    read -p "  Tem certeza que deseja desinstalar COMPLETAMENTE o proxy? (s/n): " confirm
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
        return
    fi

    echo -e "\n  ${YELLOW}Desinstalando e removendo todos os serviços...${RESET}"
    
    if [ -s "$PORTS_FILE" ]; then
        while IFS='|' read -r port _ _; do
            echo -e "  ⏹️ Parando porta ${port}..."
            systemctl stop "neweraproxy_${port}.service" >/dev/null 2>&1
            systemctl disable "neweraproxy_${port}.service" >/dev/null 2>&1
            rm -f "/etc/systemd/system/neweraproxy_${port}.service"
        done < "$PORTS_FILE"
    fi

    systemctl daemon-reload
    
    rm -rf /opt/neweraproxy
    rm -rf "$CONFIG_DIR"
    rm -f /usr/local/bin/neweraproxy

    echo -e "\n${GREEN}✅ NEW ERA PROXY DESINSTALADO COM SUCESSO!${RESET}"
    sleep 3
    exit 0
}

show_menu() {
    clear
    echo -e "${BLUE}==============================================================${RESET}"
    echo -e "           ${WHITE_BG}       🔥 NEW ERA PROXY MANAGER v1.0.0 🔥        ${RESET}"
    echo -e "           ${CYAN}         O ÁPICE DA TECNOLOGIA EM RUST           ${RESET}"
    echo -e "${BLUE}==============================================================${RESET}"
    
    # Exibir proxies ativos
    if [ ! -s "$PORTS_FILE" ]; then
        echo -e "  PORTAS ATIVAS: ${RED}NENHUMA PORTA ON${RESET}"
    else
        echo -e "  PORTAS ATIVAS:"
        while IFS='|' read -r port ssl status ssh_port vpn_port ws_path custom_resp; do
            local ssl_badge="${RED}[PLAIN]${RESET}"
            if [ "$ssl" == "true" ]; then
                ssl_badge="${GREEN}[SSL/TLS]${RESET}"
            fi
            local details=""
            if [ -n "$ws_path" ]; then
                details=" | Path: $ws_path"
            fi
            echo -e "  • Porta: ${YELLOW}$port${RESET} $ssl_badge | Status: ${CYAN}$status${RESET} | SSH: $ssh_port | VPN: $vpn_port$details"
        done < "$PORTS_FILE"
    fi
    
    echo -e "${BLUE}==============================================================${RESET}"
    echo -e "  ${RED}[${CYAN}01${RED}] ${WHITE}◉ ${YELLOW}ATIVAR NOVO PROXY${RESET}"
    echo -e "  ${RED}[${CYAN}02${RED}] ${WHITE}◉ ${YELLOW}DESATIVAR PROXY EXISTENTE${RESET}"
    echo -e "  ${RED}[${CYAN}03${RED}] ${WHITE}◉ ${YELLOW}REINICIAR TODOS OS PROXIES${RESET}"
    echo -e "  ${RED}[${CYAN}04${RED}] ${WHITE}◉ ${YELLOW}INSTALAR CERTIFICADO SSL (DOMÍNIO / LET'S ENCRYPT)${RESET}"
    echo -e "  ${RED}[${CYAN}05${RED}] ${WHITE}◉ ${YELLOW}VISUALIZAR LOGS EM TEMPO REAL${RESET}"
    echo -e "  ${RED}[${CYAN}06${RED}] ${WHITE}◉ ${YELLOW}DESINSTALAR NEW ERA PROXY${RESET}"
    echo -e "  ${RED}[${CYAN}00${RED}] ${WHITE}◉ ${YELLOW}SAIR DO MENU${RESET}"
    echo -e "${BLUE}==============================================================${RESET}"
    read -p "  SUA OPÇÃO (0-6): " option

    case $option in
        1|01)
            add_proxy_port
            ;;
        2|02)
            del_proxy_port
            ;;
        3|03)
            restart_all_proxies
            ;;
        4|04)
            setup_certbot_ssl
            ;;
        5|05)
            view_logs
            ;;
        6|06)
            uninstall_newera
            ;;
        0|00)
            clear
            exit 0
            ;;
        *)
            echo -e "\n${RED}  ❌ Opção inválida!${RESET}"
            sleep 1
            ;;
    esac
}

while true; do
    show_menu
done
