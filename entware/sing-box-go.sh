#!/bin/sh
# === Installer by @pegakmop ===

HRNEO_DIR="/opt/share/www/sing-box-go"
INDEX_FILE="$HRNEO_DIR/index.php"
MANIFEST_FILE="$HRNEO_DIR/manifest.json"
LIGHTTPD_CONF_DIR="/opt/etc/lighttpd/conf.d"
LIGHTTPD_CONF_FILE="$LIGHTTPD_CONF_DIR/80-sing-box-go.conf"
ip_addres=$(ip addr show br0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

echo "[*] Проверка наличия Entware..."
if ! command -v opkg >/dev/null 2>&1; then
    echo "❌ Entware не найден. Убедитесь, что он установлен и /opt примонтирован."
    exit 1
fi

echo "[*] Обновление списка пакетов..."
if ! opkg update && opkg upgrade >/dev/null 2>&1; then
    echo "❌ Не удалось обновить список пакетов."
    ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net" >/dev/null 2>&1
    ndmc -c "system configuration save" >/dev/null 2>&1
    exit 1
fi

echo "[*] Установка Lighttpd и PHP8..."
if ! opkg install lighttpd lighttpd-mod-cgi lighttpd-mod-setenv lighttpd-mod-redirect lighttpd-mod-rewrite php8 php8-cgi php8-cli php8-mod-curl php8-mod-openssl php8-mod-session sing-box-go jq >/dev/null 2>&1; then
    echo "❌ Ошибка при установке пакетов."
    exit 1
fi

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
ln -sf /opt/etc/init.d/S80lighttpd /opt/bin/sbp
chmod +x "$INDEX_FILE"
/opt/etc/init.d/S80lighttpd restart
echo "[*] Установка завершена."
echo "[*] Установщик веб панели удален."
rm "$0"
echo ""
echo "sing-box-go create @pegakmop installed"
echo ""
echo "Перейдите на http://$ip_addres:94"
echo ""
