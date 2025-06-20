#!/bin/sh

# === format disk Installer by @pegakmop ===

HRNEO_DIR="/opt/share/www/format"
INDEX_FILE="$HRNEO_DIR/index.php"
MANIFEST_FILE="$HRNEO_DIR/format_disk.sh"
LIGHTTPD_CONF_DIR="/opt/etc/lighttpd/conf.d"
LIGHTTPD_CONF_FILE="$LIGHTTPD_CONF_DIR/80-hrneo.conf"

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
    echo "[*] Удаление старого скрипта..."
    rm "$MANIFEST_FILE"
fi

echo "[*] Создание нового скрипта..."
cat > "$MANIFEST_FILE" << 'EOF'
#!/bin/sh

ENTWARE_DEV=$(mount | grep 'on /opt ' | awk '{print $1}')

echo "["
SEP=""
for MNT in /tmp/mnt/*; do
  DEV=$(mount | grep "on $MNT " | awk '{print $1}')
  [ -n "$DEV" ] || continue

  [ "$DEV" = "$ENTWARE_DEV" ] && continue

  LABEL=$(basename "$MNT")
  echo "$SEP{\"mnt\":\"$MNT\",\"dev\":\"$DEV\",\"label\":\"$LABEL\"}"
  SEP=","
done
echo "]"
EOF

if [ -f "$INDEX_FILE" ]; then
    echo "[*] Удаление старого index.php..."
    //rm "$INDEX_FILE"
fi

echo "[*] Создание нового index.php..."
cat > "$INDEX_FILE" << 'EOF'
<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

function getEntwareInfo() {
    $entwareDev = shell_exec("mount | grep 'on /opt ' | awk '{print \$1}'");
    $entwareDev = is_string($entwareDev) ? trim($entwareDev) : '';
    return ['dev' => $entwareDev];
}

function getAvailableMountsProxy() {
    $output = shell_exec("sh " . __DIR__ . "/format_disk.sh");
    return json_decode($output, true) ?: [];
}

$message = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $_POST['confirm'] === 'yes') {
    $target = $_POST['target'] ?? '';
    if (preg_match('#^/tmp/mnt/[^/]+$#', $target) && is_dir($target)) {
        shell_exec("rm -rf " . escapeshellarg($target) . "/*");
        $message = "✅ Раздел очищен: <code>$target</code>";
    } else {
        $message = "❌ Неверный путь к разделу.";
    }
}

$entware = getEntwareInfo();
$available = getAvailableMountsProxy();
?>
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8" />
  <title>Очистка разделов (кроме активного Entware)</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <style>
    body {
      font-family: sans-serif;
      background: #f4f4f4;
      margin: 0;
      padding: 1em;
    }
    .header { margin-bottom: 1em; }
    .block {
      background: white;
      padding: 1em;
      margin-bottom: 1em;
      border-radius: 8px;
      box-shadow: 0 0 4px rgba(0,0,0,0.1);
    }
    code {
      background: #eee;
      padding: 0.2em 0.4em;
      border-radius: 3px;
      font-size: 0.95em;
    }
    .warning {
      background: #d33;
      color: white;
      border: none;
      width: 100%;
      padding: 0.8em;
      font-size: 1em;
      margin-top: 1em;
      border-radius: 5px;
      font-weight: bold;
    }
    .warning:hover { opacity: 0.9; }
    .mnt-label { font-weight: bold; font-size: 1.1em; margin-bottom: 0.5em; }
    .mnt-info { font-size: 0.9em; color: #555; }
  </style>
</head>
<body>

  <div class="header">
    <h2>🧹 Полная очистка накопителей:</h2>
    <p>Создал для своего удобства: @pegakmop</p>
    <?php if ($message): ?>
      <div class="block"><strong><?= $message ?></strong></div>
    <?php endif; ?>
  </div>

  <div class="block">
    <p><strong>Активный Entware:</strong><br>
    Не очищаемый диск: <code><?= htmlspecialchars($entware['dev']) ?></code></p>
  </div>

  <?php if (empty($available)): ?>
    <div class="block">
      <p>❌ Нет доступных разделов для очистки.</p>
    </div>
  <?php else: ?>
    <?php foreach ($available as $mnt): ?>
      <div class="block">
        <div class="mnt-label"><?= htmlspecialchars($mnt['label']) ?></div>
        <div class="mnt-info">Путь: <code><?= htmlspecialchars($mnt['mnt']) ?></code></div>
        <div class="mnt-info">Устройство: <code><?= htmlspecialchars($mnt['dev']) ?></code></div>
        <form method="POST" onsubmit="return confirm('Удалить все файлы в <?= $mnt['mnt'] ?>?');">
          <input type="hidden" name="target" value="<?= htmlspecialchars($mnt['mnt']) ?>">
          <input type="hidden" name="confirm" value="yes">
          <button type="submit" class="warning">🧨 Очистить</button>
        </form>
      </div>
    <?php endforeach; ?>
  <?php endif; ?>

</body>
</html>
EOF

if [ -f "$LIGHTTPD_CONF_FILE" ]; then
    echo "[*] Удаление конфигурации Lighttpd..."
    rm "$LIGHTTPD_CONF_FILE"
fi

echo "[*] Создание конфигурации Lighttpd..."
cat > "$LIGHTTPD_CONF_FILE" << 'EOF'
server.port := 8098
server.username := ""
server.groupname := ""

$HTTP["host"] =~ "^(.+):8098$" {
    url.redirect = ( "^/format/" => "http://%1:98" )
    url.redirect-code = 301
}

$SERVER["socket"] == ":98" {
    server.document-root = "/opt/share/www/"
    server.modules += ( "mod_cgi" )
    cgi.assign = ( ".php" => "/opt/bin/php8-cgi" )
    setenv.set-environment = ( "PATH" => "/opt/bin:/usr/bin:/bin" )
    index-file.names = ( "index.php" )
    url.rewrite-once = ( "^/(.*)" => "/format/$1" )
}
EOF

echo "[*] Установка прав и перезапуск..."
chmod +x /opt/share/www/format/format-disk.sh
ln -sf /opt/etc/init.d/S80lighttpd /opt/bin/php
chmod +x "$INDEX_FILE"
/opt/etc/init.d/S80lighttpd enable
/opt/etc/init.d/S80lighttpd stop
/opt/etc/init.d/S80lighttpd restart
echo "[*] Установка завершена."
echo "[*] Установщик веб панели удален."
rm "$0"
echo ""
echo "format disk create @pegakmop installed"
echo ""
echo "Перейдите на http://<IP-роутера>:98"
echo ""
