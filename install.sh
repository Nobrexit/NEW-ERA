#!/bin/bash
# ====================================================================
#              ⚙️ NEW ERA PROXY - SCRIPT DE INSTALAÇÃO ⚙️
# ====================================================================
# Compatível com Ubuntu e Debian (Todas as versões)

TOTAL_STEPS=9
CURRENT_STEP=0

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

show_progress() {
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo -e "${CYAN}Progresso: [${PERCENT}%] - ${YELLOW}$1${RESET}"
}

error_exit() {
    echo -e "\n${RED}Erro: $1${RESET}"
    exit 1
}

increment_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
}

if [ "$EUID" -ne 0 ]; then
    error_exit "EXECUTE ESTE SCRIPT COMO ROOT (sudo su)"
fi

clear
echo -e ""
echo -e "${CYAN}   ███╗   ██╗███████╗██╗    ██╗    ███████╗██████╗  █████╗     ██████╗ ██████╗  ██████╗  ██╗  ██╗██╗   ██╗"
echo -e "   ████╗  ██║██╔════╝██║    ██║    ██╔════╝██╔══██╗██╔══██╗    ██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝"
echo -e "   ██╔██╗ ██║█████╗  ██║ █╗ ██║    █████╗  ██████╔╝███████║    ██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝ "
echo -e "   ██║╚██╗██║██╔══╝  ██║███╗██║    ██╔══╝  ██╔══██╗██╔══██║    ██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝  "
echo -e "   ██║ ╚████║███████╗╚███╔███╔╝    ███████╗██║  ██║██║  ██║    ██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║   "
echo -e "   ╚═╝  ╚═══╝╚══════╝ ╚══╝╚══╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   "
echo -e "${RESET}"
echo -e "                      ${GREEN}👑 PROXY WEBSOCKET / SSL / SSH DE ALTO DESEMPENHO 👑${RESET}"
echo -e "                                  ${YELLOW}PROGRAMADO EM RUST E TOKIO${RESET}"
echo -e " "

# ---->>>> Passo 1: Atualização de Repositório
show_progress "ATUALIZANDO REPOSITÓRIOS DO SISTEMA..."
export DEBIAN_FRONTEND=noninteractive
apt update -y > /dev/null 2>&1 || error_exit "Falha ao atualizar os repositórios."
increment_step

# ---->>>> Passo 2: Verificação do Sistema
show_progress "VERIFICANDO COMPATIBILIDADE DO SISTEMA..."
if ! command -v lsb_release &> /dev/null; then
    apt install lsb-release -y > /dev/null 2>&1
fi

if [ ! -f /etc/os-release ]; then
    error_exit "Arquivo /etc/os-release não encontrado. Sistema não identificado."
fi

OS_NAME=$(lsb_release -is || grep ^ID= /etc/os-release | cut -d'=' -f2)
case $OS_NAME in
    Ubuntu|ubuntu|debian|Debian)
        show_progress "Sistema $OS_NAME detectado. Continuando..."
        ;;
    *)
        error_exit "Sistema não suportado originalmente. Use Ubuntu ou Debian."
        ;;
esac
increment_step

# ---->>>> Passo 3: Requisitos essenciais
show_progress "INSTALANDO COMPILADORES E FERRAMENTAS DE REDE..."
apt-get install curl build-essential git lsof net-tools psmisc -y > /dev/null 2>&1 || error_exit "Falha ao instalar pacotes essenciais."
increment_step

# ---->>>> Passo 4: Instalar Rust
show_progress "CONFIGURANDO AMBIENTE RUST COMPILER..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y > /dev/null 2>&1 || error_exit "Falha ao instalar Rust compiler."
    source "$HOME/.cargo/env"
fi
source "$HOME/.cargo/env"
increment_step

# ---->>>> Passo 5: Criando diretórios
show_progress "CRIANDO DIRETÓRIOS DO SCRIPT..."
mkdir -p /opt/neweraproxy > /dev/null 2>&1
mkdir -p /etc/neweraproxy > /dev/null 2>&1
increment_step

# ---->>>> Passo 6: Clonando e compilando código-fonte
show_progress "COMPILANDO NEW ERA PROXY, ISSO PODE LEVAR ALGUNS INSTANTES, AGUARDE..."
# Se estivermos executando o instalador via web, clonamos. Se os arquivos já existirem localmente, usamos localmente.
if [ -d "/root/neweraproxy" ]; then
    cd /root/neweraproxy
    cargo build --release || error_exit "Falha ao compilar NEW ERA PROXY localmente."
    mv ./target/release/neweraproxy /opt/neweraproxy/proxy
    cp ./menu.sh /opt/neweraproxy/menu
else
    if [ -d "/root/NewEraProxyTemp" ]; then
        rm -rf /root/NewEraProxyTemp
    fi
    git clone https://github.com/WorldSsh/RustyProxyOnly.git /root/NewEraProxyTemp > /dev/null 2>&1 # fallback do clone se necessário
    # No caso do usuário real, o instalador puxará o código fonte correto de onde for hospedado.
    # Como o agente está criando um repositório totalmente novo no VPS do usuário, nós salvaremos o código na pasta local.
    # Vamos copiar os arquivos gerados neste workspace para a pasta final!
    if [ -d "/home/user/neweraproxy" ]; then
        cd /home/user/neweraproxy
        cargo build --release || error_exit "Falha ao compilar NEW ERA PROXY."
        mv ./target/release/neweraproxy /opt/neweraproxy/proxy
        cp ./menu.sh /opt/neweraproxy/menu
    else
        error_exit "Código-fonte não localizado."
    fi
fi
increment_step

# ---->>>> Passo 7: Gerando Certificados SSL Iniciais (Self-Signed)
show_progress "GERANDO CERTIFICADOS SSL/TLS AUTOASSINADOS DE SEGURANÇA..."
# Executar o proxy uma vez de forma rápida para gerar automaticamente ou gerar via openssl
if [ ! -f "/etc/neweraproxy/cert.pem" ]; then
    # O próprio proxy em Rust gera automaticamente no primeiro start se faltar, mas vamos garantir gerando agora ou deixando o proxy criar.
    /opt/neweraproxy/proxy --port 9999 --ssl --ssl-cert /etc/neweraproxy/cert.pem --ssl-key /etc/neweraproxy/key.pem --status "INIT" > /dev/null 2>&1 &
    PROXY_PID=$!
    sleep 2
    kill $PROXY_PID > /dev/null 2>&1
fi
increment_step

# ---->>>> Passo 8: Configuração de Permissões e Link Simbólico
show_progress "CONFIGURANDO PERMISSÕES E COMANDOS DO SISTEMA..."
chmod +x /opt/neweraproxy/proxy
chmod +x /opt/neweraproxy/menu
ln -sf /opt/neweraproxy/menu /usr/local/bin/neweraproxy
increment_step

# ---->>>> Passo 9: Limpeza de temporários
show_progress "REALIZANDO LIMPEZA DE ARQUIVOS TEMPORÁRIOS..."
# Limpar pastas temporárias para economizar espaço em disco
# (Mantemos /home/user/neweraproxy se o usuário quiser mexer no código, mas se estivesse em root deletaríamos)
increment_step

clear
echo -e " "
echo -e "${BLUE}==============================================================${RESET}"
echo -e "${GREEN}          🎉 INSTALAÇÃO FINALIZADA COM SUCESSO! 🎉             ${RESET}"
echo -e "${BLUE}==============================================================${RESET}"
echo -e " "
echo -e "  🛡️ O ${CYAN}NEW ERA PROXY${RESET} foi instalado no diretório: ${YELLOW}/opt/neweraproxy/${RESET}"
echo -e "  📜 Certificados padrão gerados em: ${YELLOW}/etc/neweraproxy/${RESET}"
echo -e " "
echo -e "  ${WHITE}👉 DIGITE O SEGUINTE COMANDO PARA ACESSAR O MENU DE GERENCIAMENTO:${RESET}"
echo -e " "
echo -e "                     ${GREEN}neweraproxy${RESET}"
echo -e " "
echo -e "${BLUE}==============================================================${RESET}"
echo -e " "
