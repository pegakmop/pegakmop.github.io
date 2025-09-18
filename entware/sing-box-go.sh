#!/bin/sh
# === Installer NeoFit create by @pegakmop ===

HRNEO_DIR="/opt/share/www/sing-box-go"
INDEX_FILE="$HRNEO_DIR/index.php"
MANIFEST_FILE="$HRNEO_DIR/manifest.json"
LIGHTTPD_CONF_DIR="/opt/etc/lighttpd/conf.d"
LIGHTTPD_CONF_FILE="$LIGHTTPD_CONF_DIR/80-sing-box-go.conf"
ip_addres=$(ip addr show br0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

echo "[*] Добавление DNS 9.9.9.9 и 8.8.4.4"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net" >/dev/null 2>&1
ndmc -c "dns-proxy tls upstream 8.8.4.4 sni dns.google" >/dev/null 2>&1
ndmc -c "system configuration save" >/dev/null 2>&1

echo "[*] Проверка наличия Entware..."
if ! command -v opkg >/dev/null 2>&1; then
    echo "[X] Entware не найден. Убедитесь, что он установлен и /opt примонтирован."
    exit 1
fi

echo "[*] Обновление списка пакетов..."
if ! opkg update >/dev/null 2>&1; then
    echo "[X] Не удалось обновить список пакетов."
    echo "[*] Пробуем задать DNS и запустить скрипт заново..."
    ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net" >/dev/null 2>&1
    ndmc -c "system configuration save" >/dev/null 2>&1
    curl -o /opt/root/sing-box-go.sh https://raw.githubusercontent.com/pegakmop/pegakmop.github.io/main/entware/sing-box-go.sh && chmod +x /opt/root/sing-box-go.sh && /opt/root/sing-box-go.sh
    exit 1
fi

echo "[*] Установка необходимых пакетов..."
REQUIRED_PACKAGES="lighttpd lighttpd-mod-cgi lighttpd-mod-setenv lighttpd-mod-redirect lighttpd-mod-rewrite php8 php8-cgi php8-cli php8-mod-curl php8-mod-openssl php8-mod-session sing-box-go jq"
for pkg in $REQUIRED_PACKAGES; do
    if ! opkg list-installed | grep -q "^$pkg "; then
        echo "[+] Установка $pkg..."
        if ! opkg install "$pkg" >/dev/null 2>&1; then
            echo "[X] Ошибка при установке пакета: $pkg"
            exit 1
        fi
    fi
done

echo "[*] Создание директорий..."
mkdir -p "$HRNEO_DIR"
mkdir -p "$LIGHTTPD_CONF_DIR"

if [ -f "$MANIFEST_FILE" ]; then
    echo "[*] Удаление старого manifest.json..."
    rm "$MANIFEST_FILE"
fi

echo "[*] Создание нового manifest.json..."
cat > "$MANIFEST_FILE" << 'EOF'
{
  "name": "sing-box-go",
  "short_name": "sing-box-go",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#1b2434",
  "theme_color": "#fff",
  "orientation": "any",
  "prefer_related_applications": false,
  "icons": [
    {
      "src": "180x180.png",
      "sizes": "180x180",
      "type": "image/png"
    }
  ]
}
EOF

echo "[*] Скачивание иконок для pwa"
curl -sL https://raw.githubusercontent.com/pegakmop/hrneo/refs/heads/main/opt/share/www/hrneo/180x180.png -o /opt/share/www/sing-box-go/180x180.png
curl -sL https://raw.githubusercontent.com/pegakmop/hrneo/refs/heads/main/opt/share/www/hrneo/apple-touch-icon.png -o /opt/share/www/sing-box-go/apple-touch-icon.png

if [ -f "$INDEX_FILE" ]; then
    echo "[*] Удаление старого index.php..."
    #rm "$INDEX_FILE"
fi

echo "[*] Создание нового index.php..."
#curl -sL https://raw.githubusercontent.com/pegakmop/neofit/refs/heads/main/index.php -o /opt/share/www/sing-box-go/index.php
curl -sL https://raw.githubusercontent.com/pegakmop/pegakmop.github.io/refs/heads/main/entware/sing-box-go-gen.php -o /opt/share/www/sing-box-go/index.php

if [ -f "$LIGHTTPD_CONF_FILE" ]; then
    echo "[*] Удаление конфигурации Lighttpd..."
    rm "$LIGHTTPD_CONF_FILE"
fi

echo "[*] Создание конфигурации Lighttpd..."
cat > "$LIGHTTPD_CONF_FILE" << 'EOF'
server.port := 8094
server.username := ""
server.groupname := ""

$HTTP["host"] =~ "^(.+):8094$" {
    url.redirect = ( "^/sing-box-go/" => "http://%1:94" )
    url.redirect-code = 301
}

$SERVER["socket"] == ":94" {
    server.document-root = "/opt/share/www/"
    server.modules += ( "mod_cgi" )
    cgi.assign = ( ".php" => "/opt/bin/php8-cgi" )
    setenv.set-environment = ( "PATH" => "/opt/bin:/usr/bin:/bin" )
    index-file.names = ( "index.php" )
    url.rewrite-once = ( "^/(.*)" => "/sing-box-go/$1" )
}
EOF

echo "[*] Установка прав и перезапуск..."
ln -sf /opt/etc/init.d/S80lighttpd /opt/bin/sbg
/opt/etc/init.d/S80lighttpd restart
echo "[*] Установка завершена."
echo "[*] Установщик веб панели удален."
rm "$0"
echo ""
echo "sing-box-go create @pegakmop installed"
echo ""
echo "Перейдите на http://$ip_addres:94"
echo ""
