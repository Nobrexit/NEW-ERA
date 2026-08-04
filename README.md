# 🔥 NEW ERA PROXY 🔥

O **NEW ERA PROXY** é uma evolução revolucionária de alta performance e segurança para tunelamento SSH, VPN e Websocket. Desenvolvido em **Rust** utilizando o ecossistema assíncrono **Tokio** e segurança criptográfica de ponta com **Rustls**, ele oferece uma solução consolidada "tudo em um" para administradores de VPS e bypass de restrições de provedores.

Esta versão totalmente nova traz o que há de mais avançado em engenharia de software e redes, eliminando a necessidade de ferramentas externas adicionais (como Stunnel, HAProxy ou Nginx) ao incorporar terminação TLS nativa e sniffing inteligente de protocolos.

---

## ✨ Principais Diferenciais e Funcionalidades

1. **🚀 Terminação TLS Nativa (Porta 443 Sem intermediários)**
   - O proxy pode escutar diretamente na porta 443 e lidar com criptografia SSL/TLS de forma assíncrona ultra-rápida.
   - Ideal para **SSL/TLS Websocket Tunneling** seguro, disfarçando o tráfego de túneis como conexões HTTPS legítimas para servidores da web.

2. **🔑 Auto-Geração de Certificados de Segurança (Self-Signed)**
   - Caso os arquivos de certificado e chave privada não existam no sistema, o proxy usa a biblioteca `rcgen` para **gerar na hora e de forma automática** certificados autoassinados X.509 robustos, garantindo que o serviço inicie sem erros imediatamente.

3. **📜 Assistente Oficial de Certificados Let's Encrypt (Certbot)**
   - O menu interativo conta com uma integração direta ao **Certbot**. Ele automatiza a obtenção de certificados SSL legítimos gratuitos para o seu domínio, eliminando de uma vez por todas erros de certificado e garantindo máxima credibilidade do túnel.

4. **🕵️ Sniffing Dinâmico de Protocolos (Portas Multifunções)**
   - O proxy não apenas aceita conexões WebSocket, ele analisa os bytes iniciais de forma inteligente (Dynamic Protocol Sniffing).
   - Se o cliente for um **SSH direto** (como PuTTY ou OpenSSH), ele ignora o handshake HTTP e conecta direto ao SSH.
   - Se for um **Websocket Injector** (como Http Custom, HA Tunnel, SocksIP, HTTP Injector), ele processa o handshake e direciona ao SSH ou OpenVPN com base no conteúdo!
   - Isso permite que você tenha clientes Websocket HTTP, Websocket SSL e SSH Direto na **mesma porta de forma transparente!**

5. **🎛️ Painel de Gerenciamento Avançado (Menu Bash)**
   - Um dashboard visualmente impactante, colorido e totalmente em português.
   - Suporte a múltiplas portas simultâneas com configurações 100% independentes (uma porta pode ter SSL, outra plain TCP, com diferentes caminhos WebSocket, mensagens de status e portas de destino).
   - Visualizador de Logs em tempo real integrado via `journalctl`.

6. **⚡ Performance e Concorrência de Elite**
   - Baseado no ecossistema assíncrono de Rust (`tokio` + `tokio-rustls`).
   - Gerenciamento de memória seguro com zero vazamentos (Memory Safety) e baixíssimo consumo de CPU/RAM, otimizado para VPSs de qualquer porte (até as de 512MB RAM).

---

## 🛠️ Como Instalar e Rodar

Para instalar o **NEW ERA PROXY** e desfrutar do que há de melhor em redes modernas, execute o seguinte comando no seu servidor Ubuntu/Debian como **root**:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/WorldSsh/RustyProxyOnly/refs/heads/main/install.sh)
```
*(Nota: O script de instalação acima instala as dependências, compila o código Rust em release com otimizações agressivas de compilação, e configura o atalho do menu).*

### ⌨️ Comando para Gerenciamento
Após a instalação terminar, basta digitar o comando abaixo no terminal a qualquer momento para abrir o menu interativo:
```bash
neweraproxy
```

---

## 📂 Estrutura de Diretórios Instalada

- `/opt/neweraproxy/proxy` — Binário compilado de alta performance em Rust.
- `/opt/neweraproxy/menu` — Script interativo do painel de controle.
- `/opt/neweraproxy/ports` — Registro de portas ativas e suas configurações dinâmicas.
- `/etc/neweraproxy/` — Pasta onde os certificados SSL (`cert.pem` e `key.pem`) são instalados e gerenciados.
- `/usr/local/bin/neweraproxy` — Link simbólico global para acesso rápido.

---

## 🛠️ Detalhes de Parâmetros do Executável

O binário `proxy` aceita as seguintes flags para total controle:

| Flag | Descrição | Valor Padrão |
|---|---|---|
| `-p, --port` | Porta para o proxy escutar | `80` |
| `-s, --ssl` | Ativar a terminação de criptografia SSL/TLS | Desativado (Plain TCP) |
| `--ssl-cert` | Caminho do arquivo de certificado SSL (PEM) | `/etc/neweraproxy/cert.pem` |
| `--ssl-key` | Caminho do arquivo de chave privada SSL (PEM) | `/etc/neweraproxy/key.pem` |
| `--status` | Mensagem de status personalizada para handshakes | `"NEW ERA PROXY"` |
| `--ssh-port` | Porta local do servidor SSH para encaminhamento | `22` |
| `--vpn-port` | Porta local do OpenVPN para encaminhamento | `1194` |
| `--ws-path` | Filtro opcional de caminho WebSocket (Ex: `/ws`) | Sem filtro |
| `--custom-response` | Envia uma resposta HTTP estática personalizada direto | Handshake triplo legado |

---

## 💎 Créditos e Evolução

- **Nome do Projeto:** NEW ERA PROXY
- **Linguagem:** Rust (Edition 2021)
- **Autor/Evolução:** Desenvolvido como uma nova era em tunelamento, focado em alta tecnologia e arquitetura de redes avançada.
