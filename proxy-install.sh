#!/bin/bash

set -e  # Остановить выполнение при ошибке

# Проверяем, запущен ли скрипт от root
if [[ $EUID -ne 0 ]]; then
    echo "Этот скрипт нужно запускать с правами root (используйте sudo)"
    exit 1
fi

# Делаем скрипт исполняемым
chmod +x "$0"

# Запрос порта у пользователя
read -p "Введите порт для прокси (Enter для 39666): " PROXY_PORT
PROXY_PORT=${PROXY_PORT:-39666}

# Запрос пользователей
USERS=()
PASSWORDS=()
USE_AUTH=false

while true; do
    read -p "Добавить пользователя? (y/n): " ADD_USER
    if [[ "$ADD_USER" != "y" ]]; then
        break
    fi
    USE_AUTH=true
    read -p "Введите логин: " LOGIN
    read -s -p "Введите пароль: " PASSWORD
    echo ""
    USERS+=("$LOGIN")
    PASSWORDS+=("$PASSWORD")
done

# Файл со списком доменов
DOMAINS_LIST="/etc/proxy_list.txt"
DOMAINS=(
    "*.rutracker.org" "*.ntc.party" "*.lolz.guru" "*.zelenka.guru"
    "*.x.com" "*.twitter.com" "*.twimg.com" "*.t.co" "play.google.com"
    "news.google.com" "cloudflare-ech.com" "*.torproject.org" "*.soundcloud.com"
    "amnezia.org" "*.matrix.org" "*.discord.*" "*.discordapp.*" "*.discordcdn.com"
    "discordstatus.com" "dis.gd" "discord-attachments-uploads-prd.storage.googleapis.com"
    "*.googlevideo.com" "youtubei.googleapis.com" "*.ytimg.com" "*.ggpht.com"
    "*.youtube.com" "youtubeembeddedplayer.googleapis.com" "ytimg.l.google.com"
    "jnn-pa.googleapis.com" "*.youtube-nocookie.com" "*.youtube-ui.l.google.com"
    "*.yt-video-upload.l.google.com" "*.wide-youtube.l.google.com" "*.youtu.be"
    "*.yt.be" "*.znanija.com" "*.instagram.com" "*.fbcdn.net" "*.facebook.com"
    "*.fbsbx.com" "*.cdninstagram.com" "*.roskomsvoboda.org" "*.medium.com"
    "*.viber.com" "*.signal.org" "*.jut.su" "*.linktr.ee" "*.musixmatch.com"
    "*.zendesk.com" "*.protonmail.com" "*.proton.me" "*.protonvpn.com"
    "*.censortracker.org" "*.shields.io" "*.kinozal.tv" "*.rutor.org" "*.kinovibe.co"
    "*.patreon.com" "*.avira.com" "*.windscribe.com" "*.adguard-vpn.com" "*.finevpn.org"
    "*.seed4.me" "*.hide.me" "*.chatgpt.com" "*.openai.com" "*.oaistatic.com"
    "*.oaiusercontent.com" "*.auth0.com" "gemini.google.com" "aistudio.google.com"
    "generativelanguage.googleapis.com" "alkalimakersuite-pa.clients6.google.com"
    "copilot.microsoft.com" "sydney.bing.com" "edgeservices.bing.com" "*.claude.ai"
    "*.anthropic.com" "aisandbox-pa.googleapis.com" "*.pki.goog" "*.labs.google"
    "notebooklm.google.com" "webchannel-alkalimakersuite-pa.clients6.google.com"
    "*.spotify.com" "*.scdn.co" "*.notion.so" "*.canva.com" "*.intel.com" "*.dell.com"
    "*.codeium.com" "*.tiktok.com" "api.github.com" "*.githubcopilot.com"
    "proactivebackend-pa.googleapis.com" "rewards.bing.com" "*.archive.org" "*.sora.com"
    "datalore.jetbrains.com" "plugins.jetbrains.com"
)

# Запрос о включении логирования
read -p "Включить логирование? (y/n): " ENABLE_LOGGING
LOGGING_ENABLED=false
if [[ "$ENABLE_LOGGING" == "y" ]]; then
    LOGGING_ENABLED=true
fi

# Выбор прокси
echo "Выберите прокси-сервер для установки:"
echo "1) Squid"
echo "2) 3proxy"
read -p "Введите номер (1/2): " CHOICE

install_squid() {
    echo "Устанавливаем Squid..."
    apt update && apt install -y squid apache2-utils

    echo "Настраиваем Squid..."
    cat <<EOF > /etc/squid/squid.conf
http_port $PROXY_PORT
EOF

    if $USE_AUTH; then
        echo "Включаем авторизацию..."
        cat <<EOF >> /etc/squid/squid.conf
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic realm Proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
EOF
        # Создание файла с пользователями
        touch /etc/squid/passwd
        for ((i=0; i<${#USERS[@]}; i++)); do
            htpasswd -b /etc/squid/passwd "${USERS[i]}" "${PASSWORDS[i]}"
        done
    else
        echo "Прокси будет без авторизации!"
        echo "http_access allow all" >> /etc/squid/squid.conf
    fi

    # Создание списка доменов
    printf "%s\n" "${DOMAINS[@]}" > "$DOMAINS_LIST"
    echo "acl allowed_domains dstdomain \"$DOMAINS_LIST\"" >> /etc/squid/squid.conf
    echo "http_access allow allowed_domains" >> /etc/squid/squid.conf

    if $LOGGING_ENABLED; then
        echo "Включаем логирование..."
        echo "access_log /var/log/squid/access.log squid" >> /etc/squid/squid.conf
    else
        echo "Логирование отключено!"
    fi

    systemctl restart squid
    systemctl enable squid
    echo "Squid установлен на порту $PROXY_PORT"
}

install_3proxy() {
    echo "Устанавливаем 3proxy..."
    apt update && apt install -y 3proxy

    echo "Настраиваем 3proxy..."
    cat <<EOF > /etc/3proxy/3proxy.cfg
daemon
nserver 8.8.8.8
nserver 8.8.4.4
log /var/log/3proxy.log
logformat "L%Y-%m-%d %H:%M:%S %N %C:%c %R:%r %O %I %h %T"
EOF

    if $USE_AUTH; then
        echo "Включаем авторизацию..."
        echo "auth strong" >> /etc/3proxy/3proxy.cfg
        echo -n "users " >> /etc/3proxy/3proxy.cfg
        for ((i=0; i<${#USERS[@]}; i++)); do
            echo -n "${USERS[i]}:CL:${PASSWORDS[i]} " >> /etc/3proxy/3proxy.cfg
        done
        echo "" >> /etc/3proxy/3proxy.cfg
    else
        echo "Прокси будет без авторизации!"
        echo "auth none" >> /etc/3proxy/3proxy.cfg
    fi

    cat <<EOF >> /etc/3proxy/3proxy.cfg
allow *
proxy -n -a -p$PROXY_PORT
EOF

    if $LOGGING_ENABLED; then
        echo "Включаем логирование..."
        echo "log /var/log/3proxy.log" >> /etc/3proxy/3proxy.cfg
    else
        echo "Логирование отключено!"
    fi

    cat <<EOF > /etc/systemd/system/3proxy.service
[Unit]
Description=3proxy Proxy Server
After=network.target
[Service]
ExecStart=/usr/bin/3proxy /etc/3proxy/3proxy.cfg
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable 3proxy
    systemctl restart 3proxy
    echo "3proxy установлен на порту $PROXY_PORT"
}

case $CHOICE in
    1) install_squid ;;
    2) install_3proxy ;;
    *) echo "Неверный выбор!" ;;
esac
