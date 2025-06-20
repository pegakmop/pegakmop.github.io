#!/bin/sh

# === Installer by @pegakmop ===

HRNEO_DIR="/opt/share/www/pegakmop"
INDEX_FILE="$HRNEO_DIR/index.php"
MANIFEST_FILE="$HRNEO_DIR/manifest.json"
LIGHTTPD_CONF_DIR="/opt/etc/lighttpd/conf.d"
LIGHTTPD_CONF_FILE="$LIGHTTPD_CONF_DIR/80-pegakmop.conf"

echo "[*] Проверка Entware..."
if ! command -v opkg >/dev/null 2>&1; then
    echo "❌ Entware не найден. Убедитесь, что он установлен и /opt примонтирован."
    exit 1
fi

echo "[*] Обновление списка пакетов..."
if ! opkg update >/dev/null 2>&1; then
    echo "❌ Не удалось обновить список пакетов."
    echo "Возможно у вас не установлены DoT и DoH DNS"
    exit 1
fi

echo "[*] Установка Lighttpd и PHP8..."
if ! opkg install lighttpd lighttpd-mod-cgi lighttpd-mod-setenv lighttpd-mod-redirect lighttpd-mod-rewrite php8 php8-cgi php8-cli php8-mod-curl php8-mod-openssl php8-mod-session jq >/dev/null 2>&1; then
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
  "name": "pegakmop",
  "short_name": "pegakmop",
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
curl -sL https://raw.githubusercontent.com/pegakmop/hrneo/refs/heads/main/opt/share/www/hrneo/180x180.png -o /opt/share/www/hrneo/180x180.png
curl -sL https://raw.githubusercontent.com/pegakmop/hrneo/refs/heads/main/opt/share/www/hrneo/apple-touch-icon.png -o /opt/share/www/hrneo/apple-touch-icon.png

if [ -f "$INDEX_FILE" ]; then
    echo "[*] Удаление старого index.php..."
    #rm "$INDEX_FILE"
fi

echo "[*] Создание нового index.php..."
cat > "$INDEX_FILE" << EOF
<?php
phpinfo();
?>
EOF

if [ -f "$LIGHTTPD_CONF_FILE" ]; then
    echo "[*] Удаление конфигурации Lighttpd..."
    rm "$LIGHTTPD_CONF_FILE"
fi

echo "[*] Создание конфигурации Lighttpd..."
cat > "$LIGHTTPD_CONF_FILE" << 'EOF'
server.port := 8088
server.username := ""
server.groupname := ""

$HTTP["host"] =~ "^(.+):8088$" {
    url.redirect = ( "^/pegakmop/" => "http://%1:88" )
    url.redirect-code = 301
}

$SERVER["socket"] == ":88" {
    server.document-root = "/opt/share/www/"
    server.modules += ( "mod_cgi" )
    cgi.assign = ( ".php" => "/opt/bin/php8-cgi" )
    setenv.set-environment = ( "PATH" => "/opt/bin:/usr/bin:/bin" )
    index-file.names = ( "index.php" )
    url.rewrite-once = ( "^/(.*)" => "/pegakmop/$1" )
}
EOF

echo "[*] Установка прав и перезапуск..."
#ln -sf /opt/etc/init.d/S80lighttpd /opt/bin/php
#chmod +x "$INDEX_FILE"
/opt/etc/init.d/S80lighttpd enable
/opt/etc/init.d/S80lighttpd stop
/opt/etc/init.d/S80lighttpd restart
echo "[*] Установка завершена."
echo "[*] Установщик веб панели удален."
rm "$0"
echo ""
echo "create @pegakmop installed"
echo ""
echo "Перейдите на http://<IP-роутера>:88"
echo ""
