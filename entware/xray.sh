#!/bin/sh

# === Installer by @pegakmop ===

HRNEO_DIR="/opt/share/www/xray"
INDEX_FILE="$HRNEO_DIR/index.php"
MANIFEST_FILE="$HRNEO_DIR/manifest.json"
LIGHTTPD_CONF_DIR="/opt/etc/lighttpd/conf.d"
LIGHTTPD_CONF_FILE="$LIGHTTPD_CONF_DIR/80-xray.conf"

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
  "name": "xray",
  "short_name": "xray",
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
cat > "$INDEX_FILE" << 'EOF'
<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = file_get_contents('php://input');
    $path = '/opt/etc/xray/config.json';

    if (!is_dir(dirname($path))) mkdir(dirname($path), 0755, true);

    if (file_put_contents($path, $data)) {
        shell_exec('/opt/etc/init.d/S24xray restart');
        echo "✅ Конфигурация установлена и Xray перезапущен";
    } else {
        echo "❌ Не удалось записать конфигурацию";
    }
}
?>
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Xray Config Generator</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/styles/atom-one-dark.min.css">
  <style>
    /* Стили для оформления интерфейса */
    *, *::before, *::after {
      box-sizing: border-box;
    }
    body {
      --bg-color: #f9f9f9;
      --text-color: #333;
      --border-color: #ccc;
      --card-bg: #fff;
      --button-bg: #007BFF;
      --button-text: #fff;
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 20px;
      transition: background-color 0.3s, color 0.3s;
      background-color: var(--bg-color);
      color: var(--text-color);
    }
    body.dark-theme {
      --bg-color: #1e1e1e;
      --text-color: #c9d1d9;
      --border-color: #555;
      --card-bg: #282c34;
      --button-bg: #444;
      --button-text: #fff;
    }
    h1 {
      text-align: center;
      margin-bottom: 30px;
    }
    .controls {
      display: flex;
      justify-content: center;
      gap: 10px;
      flex-wrap: wrap;
      margin-bottom: 20px;
    }
    button {
      background-color: var(--button-bg);
      color: var(--button-text);
      border: none;
      border-radius: 20px;
      padding: 10px 20px;
      cursor: pointer;
      font-size: 16px;
      transition: opacity 0.3s;
    }
    button:hover {
      opacity: 0.9;
    }
    .interface-container {
      border: 1px solid var(--border-color);
      padding: 10px;
      margin-bottom: 10px;
      border-radius: 4px;
      background-color: var(--card-bg);
    }
    .interface-header {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 10px;
    }
    .link-field {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 8px;
    }
    input[type="text"] {
      width: 100%;
      padding: 8px;
      border: 1px solid var(--border-color);
      border-radius: 4px;
      background-color: var(--card-bg);
      color: var(--text-color);
      transition: border-color 0.3s;
    }
    .config-display {
      border: 1px solid var(--border-color);
      background-color: var(--card-bg);
      padding: 10px;
      border-radius: 4px;
      margin-top: 10px;
      max-height: 60vh;
      overflow-y: auto;
      position: relative;
    }
    .trash-btn, .add-link-btn {
      width: 32px;
      height: 32px;
      padding: 0;
      border-radius: 6px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 16px;
      background-color: var(--button-bg);
      color: var(--button-text);
      transition: opacity 0.3s;
    }
    .trash-btn:hover, .add-link-btn:hover {
      opacity: 0.9;
    }
    #warnings {
      color: #ff6b6b;
      margin-top: 10px;
    }
    #theme-toggle {
      position: fixed;
      top: 20px;
      right: 20px;
      width: 40px;
      height: 40px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 18px;
      background-color: var(--button-bg);
      color: var(--button-text);
      border: none;
      cursor: pointer;
      z-index: 1000;
    }
    @media (min-width: 600px) {
      .container {
        max-width: 600px;
        margin: 0 auto;
      }
    }
    .config-display pre {
      margin: 0;
      padding: 0;
      background: transparent;
      border: none;
    }
    .config-display code {
      display: block;
      padding: 10px;
      font-size: 14px;
      line-height: 1.5;
    }
    .copy-btn {
      position: absolute;
      top: 8px;
      right: 8px;
      z-index: 10;
      background-color: var(--button-bg);
      color: var(--button-text);
      border: none;
      border-radius: 4px;
      padding: 4px 8px;
      font-size: 14px;
      cursor: pointer;
      transition: opacity 0.3s;
    }
    .copy-btn:hover {
      opacity: 0.9;
    }
    .copy-btn2 {
      position: absolute;
      top: 38px;
      right: 8px;
      z-index: 20;
      background-color: var(--button-bg);
      color: var(--button-text);
      border: none;
      border-radius: 4px;
      padding: 4px 8px;
      font-size: 14px;
      cursor: pointer;
      transition: opacity 0.3s;
    }
    .copy-btn2:hover {
      opacity: 0.9;
    }
    .tooltip {
      position: fixed;
      top: 20px;
      left: 50%;
      transform: translateX(-50%);
      background-color: #4CAF50;
      color: white;
      padding: 8px 16px;
      border-radius: 4px;
      opacity: 0;
      transition: opacity 0.3s;
      z-index: 9999;
    }
    .tooltip.show {
      opacity: 1;
    }
  </style>
</head>
<body class="dark-theme">
  <div class="container">
    <h1>Xray Config Generator</h1>
    <div class="controls">
      <button onclick="addInterface()">Добавить</button>
      <button onclick="showUploadDialog()">Загрузить</button>
      <button onclick="generateConfig()">Сгенерировать</button>
      <button onclick="saveConfig()">Сохранить</button>
    </div>
    <div id="interfacesContainer"></div>
    <div id="configDisplay" class="config-display" style="display: none;">
      <p><button class="copy-btn" onclick="installConfigToRouter()">🚀 Установить на роутер</button></p>
      <button class="copy-btn2" onclick="copyConfigToClipboard()">📋 Копировать</button>
      <pre><code id="output" class="language-json"></code></pre>
    </div>
    <div id="warnings"></div>
  </div>
  <button id="theme-toggle" onclick="toggleTheme()">🌓</button>
  <div id="copyTooltip" class="tooltip">Скопировано!</div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/highlight.min.js"></script>
  <script>
  async function installConfigToRouter() {
  const configText = document.getElementById('output').textContent;

  try {
    const response = await fetch('/xray/index.php', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: configText
    });

    const resultText = await response.text();

    //alert(resultText); // вот тут будет показано сообщение от PHP

    // ❗Если успех — перейти обратно на index.html
    if (resultText.includes('✅')) {
      window.location.href = 'index.php?alert=success';
    }
  } catch (err) {
    //alert('Ошибка при установке конфигурации: ' + err.message);
    window.location.href = 'index.php?alert=error';
  }
}
</script>
<script>
document.addEventListener('DOMContentLoaded', function () {
  const params = new URLSearchParams(window.location.search);
  const alertParam = params.get('alert');

  if (alertParam) {
    let message = '';
    switch (alertParam) {
      case 'success':
        message = '✅ Конфигурация установлена';
        break;
      case 'error':
        message = '❌ Ошибка при установке';
        break;
      default:
        message = decodeURIComponent(alertParam); // можно передавать произвольный текст
    }

    alert(message);

    // удалим параметр alert из URL без перезагрузки
    history.replaceState(null, '', window.location.pathname);
  }
});
</script>
  <script>
    let config = {};
    let interfaceCount = 0;
    let isConfigModified = false;
    let baseSocksPort = 1080;

    // Добавление нового интерфейса
    function addInterface() {
      interfaceCount++;
      isConfigModified = true;
      const interfaceId = `interface-${interfaceCount}`;
      const container = document.createElement('div');
      container.className = 'interface-container';
      container.id = interfaceId;

      const header = document.createElement('div');
      header.className = 'interface-header';

      const deleteBtn = document.createElement('button');
      deleteBtn.className = 'trash-btn';
      deleteBtn.innerHTML = '🗑️';
      deleteBtn.title = 'Удалить интерфейс';
      deleteBtn.onclick = () => {
        container.remove();
        isConfigModified = true;
      };

      const nameInput = document.createElement('input');
      nameInput.type = 'text';
      nameInput.placeholder = 'Название интерфейса (например, socks0)';
      nameInput.value = `socks${interfaceCount - 1}`; // Название по умолчанию "socksX"
      nameInput.maxLength = 20;

      header.appendChild(deleteBtn);
      header.appendChild(nameInput);

      const linksContainer = document.createElement('div');
      linksContainer.className = 'links-container';

      const addLinkBtn = document.createElement('button');
      addLinkBtn.className = 'add-link-btn';
      addLinkBtn.innerHTML = '+';
      addLinkBtn.title = 'Добавить ссылку';
      addLinkBtn.onclick = () => {
        addLinkField(linksContainer);
        isConfigModified = true;
      };

      container.appendChild(header);
      container.appendChild(linksContainer);
      container.appendChild(addLinkBtn);

      document.getElementById('interfacesContainer').appendChild(container);
      addLinkField(linksContainer);
    }

    // Добавление поля для ссылки
    function addLinkField(container) {
      const linkField = document.createElement('div');
      linkField.className = 'link-field';

      const input = document.createElement('input');
      input.type = 'text';
      input.placeholder = 'vless://... vmess://... trojan://... ss://... socks://...';

      const deleteBtn = document.createElement('button');
      deleteBtn.className = 'trash-btn';
      deleteBtn.innerHTML = '🗑️';
      deleteBtn.title = 'Удалить ссылку';
      deleteBtn.onclick = () => {
        linkField.remove();
        isConfigModified = true;
      };

      linkField.appendChild(input);
      linkField.appendChild(deleteBtn);
      container.appendChild(linkField);
    }

    // Парсинг VLESS-ссылки для Xray
    function parseVlessLinkForXray(link) {
      const match = link.match(/vless:\/\/([^@]+)@([^:]+):(\d+)(?:\?([^#]*))?(?:#(.*))?/);
      if (!match) return null;

      const uuid = match[1];
      const server = match[2];
      const server_port = parseInt(match[3], 10);
      const params = new URLSearchParams(match[4] || "");
      const tag = decodeURIComponent(match[5] || "").trim() || `vless-${server}-${server_port}`;

      const outbound = {
        protocol: "vless",
        settings: {
          vnext: [
            {
              address: server,
              port: server_port,
              users: [
                {
                  id: uuid,
                  encryption: params.get("encryption") || "none",
                  flow: params.get("flow") || ""
                }
              ]
            }
          ]
        },
        streamSettings: {
          network: params.get("type") || "tcp",
          security: params.get("security") || "none"
        },
        tag: tag
      };

      if (outbound.streamSettings.security === "tls") {
        outbound.streamSettings.tlsSettings = {
          serverName: params.get("sni") || server,
          alpn: ["h2", "http/1.1"]
        };
      } else if (outbound.streamSettings.security === "reality") {
        outbound.streamSettings.realitySettings = {
          publicKey: params.get("pbk") || "",
          fingerprint: params.get("fp") || "chrome",
          serverName: params.get("sni") || server,
          shortId: params.get("sid") || "",
          spiderX: params.get("path") || "/"
        };
      }

      const transportType = params.get("type") || "tcp";
      if (transportType === "ws") {
        outbound.streamSettings.wsSettings = {
          path: params.get("path") || "/",
          headers: { Host: params.get("host") || server }
        };
      }

      return outbound;
    }

    // Парсинг VMess-ссылки для Xray
    function parseVmessLinkForXray(link) {
      try {
        const b64 = link.replace('vmess://', '');
        const json = JSON.parse(atob(b64.replace(/-/g, '+').replace(/_/g, '/')));
        return {
          protocol: "vmess",
          settings: {
            vnext: [
              {
                address: json.add,
                port: parseInt(json.port, 10),
                users: [
                  {
                    id: json.id,
                    alterId: json.aid ? parseInt(json.aid, 10) : 0,
                    security: json.scy || "auto"
                  }
                ]
              }
            ]
          },
          streamSettings: {
            network: json.net || "tcp",
            security: json.tls === "tls" ? "tls" : "none",
            tlsSettings: json.tls === "tls" ? { serverName: json.sni || json.add } : undefined
          },
          tag: json.ps || `vmess-${json.add}-${json.port}`
        };
      } catch (e) {
        return null;
      }
    }

    // Парсинг Trojan-ссылки для Xray
    function parseTrojanLinkForXray(link) {
      const match = link.match(/trojan:\/\/([^@]+)@([^:]+):(\d+)(?:\?([^#]*))?(?:#(.*))?/);
      if (!match) return null;
      const password = match[1];
      const server = match[2];
      const server_port = parseInt(match[3], 10);
      const params = new URLSearchParams(match[4] || "");
      const tag = decodeURIComponent(match[5] || "").trim() || `trojan-${server}-${server_port}`;
      return {
        protocol: "trojan",
        settings: {
          servers: [{ address: server, port: server_port, password }]
        },
        streamSettings: {
          network: "tcp",
          security: params.get("sni") ? "tls" : "none",
          tlsSettings: params.get("sni") ? { serverName: params.get("sni") } : undefined
        },
        tag: tag
      };
    }

    // Парсинг Shadowsocks-ссылки для Xray
    function parseShadowsocksLinkForXray(link) {
      try {
        let url = link.replace('ss://', '');
        let tag = url.includes('#') ? decodeURIComponent(url.split('#')[1]) : '';
        url = url.split('#')[0];
        const [userinfo, hostinfo] = url.includes('@') ? url.split('@') : [atob(url), ""];
        const [method, password] = userinfo.includes(':') ? userinfo.split(':') : [userinfo, ""];
        const [server, port] = hostinfo.split(':');
        return {
          protocol: "shadowsocks",
          settings: {
            servers: [{ address: server, port: parseInt(port, 10), method, password }]
          },
          tag: tag || `ss-${server}-${port}`
        };
      } catch (e) {
        return null;
      }
    }

    // Парсинг SOCKS-ссылки для Xray
    function parseSocksLinkForXray(link) {
      const match = link.match(/socks:\/\/(?:([^:]+):([^@]+)@)?([^:]+):(\d+)(?:#(.*))?/);
      if (!match) return null;
      const username = match[1] || "";
      const password = match[2] || "";
      const server = match[3];
      const server_port = parseInt(match[4], 10);
      const tag = decodeURIComponent(match[5] || "").trim() || `socks-${server}-${server_port}`;
      return {
        protocol: "socks",
        settings: {
          servers: [
            {
              address: server,
              port: server_port,
              users: username ? [{ user: username, pass: password }] : []
            }
          ]
        },
        tag: tag
      };
    }

    // Универсальная функция парсинга ссылок
    function parseLink(link) {
      if (link.startsWith('vless://')) return parseVlessLinkForXray(link);
      if (link.startsWith('vmess://')) return parseVmessLinkForXray(link);
      if (link.startsWith('trojan://')) return parseTrojanLinkForXray(link);
      if (link.startsWith('ss://')) return parseShadowsocksLinkForXray(link);
      if (link.startsWith('socks://')) return parseSocksLinkForXray(link);
      return null;
    }

    // Поиск следующего свободного порта
    function getNextFreePort(inbounds, startPort) {
      const usedPorts = new Set(inbounds.map(ib => ib.port));
      let port = startPort;
      while (usedPorts.has(port)) {
        port++;
      }
      return port;
    }

    // Генерация конфигурации
    function generateConfig() {
      if (!isConfigModified && config.inbounds && config.inbounds.length > 0) {
        const output = document.getElementById('output');
        output.textContent = JSON.stringify(config, null, 2);
        hljs.highlightElement(output);
        document.getElementById('configDisplay').style.display = 'block';
        resizeOutputContainer();
        return;
      }

      let newConfig = {
        log: { loglevel: "none" },
        inbounds: [],
        outbounds: []
      };

      let warnings = [];
      let socksPort = baseSocksPort;
      const interfaces = document.querySelectorAll('.interface-container');
      const usedTags = new Set();
      const routingRules = [];

      interfaces.forEach((interfaceContainer, index) => {
        const nameInput = interfaceContainer.querySelector('.interface-header input[type="text"]');
        const interfaceName = nameInput.value.trim() || `socks${index}`;
        const linkInputs = interfaceContainer.querySelectorAll('.links-container input[type="text"]');

        if (linkInputs.length === 0) {
          warnings.push(`⚠️ Для интерфейса "${interfaceName}" не добавлено ни одной ссылки.`);
          return;
        }

        const socksPortNew = getNextFreePort(newConfig.inbounds, socksPort);
        const inboundTag = `socks-in-${interfaceName}`;
        newConfig.inbounds.push({
          protocol: "socks",
          port: socksPortNew,
          listen: "0.0.0.0",
          tag: inboundTag,
          settings: { auth: "noauth", udp: true }
        });
        socksPort = socksPortNew + 1;

        const outboundTags = [];
        linkInputs.forEach(input => {
          const link = input.value.trim();
          if (!link) return;
          const outbound = parseLink(link);
          if (outbound) {
            if (!usedTags.has(outbound.tag)) {
              newConfig.outbounds.push(outbound);
              usedTags.add(outbound.tag);
            }
            outboundTags.push(outbound.tag);
          } else {
            warnings.push(`⚠️ Неверный формат ссылки: ${link}`);
          }
        });

        if (outboundTags.length > 0) {
          const targetOutbound = outboundTags[0]; // Берем первый outbound
          routingRules.push({
            type: "field",
            inboundTag: [inboundTag],
            outboundTag: targetOutbound
          });
        }
      });

      newConfig.outbounds.push({ protocol: "freedom", tag: "direct" });
      newConfig.outbounds.push({ protocol: "blackhole", tag: "blocked" });

      // Если интерфейсов больше одного, добавляем routing
      if (interfaces.length > 1) {
        newConfig.routing = { rules: routingRules };
      }

      config = newConfig;
      document.getElementById('warnings').innerHTML = warnings.join("<br>");

      const output = document.getElementById('output');
      output.textContent = JSON.stringify(config, null, 2);
      hljs.highlightElement(output);
      document.getElementById('configDisplay').style.display = 'block';
      resizeOutputContainer();
    }

    // Сохранение конфигурации
    function saveConfig() {
      if (!config || Object.keys(config).length === 0) {
        document.getElementById('warnings').innerHTML = "Нет конфигурации для сохранения";
        return;
      }
      const blob = new Blob([JSON.stringify(config, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'config.json';
      a.click();
      URL.revokeObjectURL(url);
    }

    // Диалог загрузки файла
    function showUploadDialog() {
      const input = document.createElement('input');
      input.type = 'file';
      input.accept = '.json';
      input.onchange = (event) => {
        const file = event.target.files[0];
        if (file) {
          const reader = new FileReader();
          reader.onload = (e) => loadedConfig(e.target.result);
          reader.readAsText(file);
        }
      };
      input.click();
    }

    // Обработка загруженной конфигурации
    function loadedConfig(jsonText) {
      try {
        const loadedConfig = JSON.parse(jsonText);
        document.getElementById('interfacesContainer').innerHTML = '';
        interfaceCount = 0;
        isConfigModified = false;
        baseSocksPort = 1080;

        if (loadedConfig.inbounds && loadedConfig.outbounds) {
          const socksInbounds = loadedConfig.inbounds.filter(ib => ib.protocol === "socks");
          if (socksInbounds.length > 0) {
            baseSocksPort = Math.max(...socksInbounds.map(ib => ib.port)) + 1;
          }

          const interfaceNames = new Set();
          socksInbounds.forEach(inbound => {
            const interfaceName = inbound.tag.replace('socks-in-', '');
            if (!interfaceNames.has(interfaceName)) {
              interfaceNames.add(interfaceName);
              interfaceCount++;
              const interfaceId = `interface-${interfaceCount}`;
              const container = document.createElement('div');
              container.className = 'interface-container';
              container.id = interfaceId;

              const header = document.createElement('div');
              header.className = 'interface-header';

              const deleteBtn = document.createElement('button');
              deleteBtn.className = 'trash-btn';
              deleteBtn.innerHTML = '🗑️';
              deleteBtn.title = 'Удалить интерфейс';
              deleteBtn.onclick = () => {
                container.remove();
                isConfigModified = true;
              };

              const nameInput = document.createElement('input');
              nameInput.type = 'text';
              nameInput.value = interfaceName;
              nameInput.maxLength = 20;

              header.appendChild(deleteBtn);
              header.appendChild(nameInput);

              const linksContainer = document.createElement('div');
              linksContainer.className = 'links-container';

              const addLinkBtn = document.createElement('button');
              addLinkBtn.className = 'add-link-btn';
              addLinkBtn.innerHTML = '+';
              addLinkBtn.title = 'Добавить ссылку';
              addLinkBtn.onclick = () => {
                addLinkField(linksContainer);
                isConfigModified = true;
              };

              container.appendChild(header);
              container.appendChild(linksContainer);
              container.appendChild(addLinkBtn);

              document.getElementById('interfacesContainer').appendChild(container);

              // Добавляем ссылки, если есть
              const rule = loadedConfig.routing ? loadedConfig.routing.rules.find(r => r.inboundTag.includes(inbound.tag)) : null;
              if (rule) {
                const outboundTag = rule.outboundTag;
                const outbound = loadedConfig.outbounds.find(o => o.tag === outboundTag);
                if (outbound) {
                  const linkField = document.createElement('div');
                  linkField.className = 'link-field';

                  const input = document.createElement('input');
                  input.type = 'text';
                  input.value = outbound.tag;

                  const deleteLinkBtn = document.createElement('button');
                  deleteLinkBtn.className = 'trash-btn';
                  deleteLinkBtn.innerHTML = '🗑️';
                  deleteLinkBtn.title = 'Удалить ссылку';
                  deleteLinkBtn.onclick = () => {
                    linkField.remove();
                    isConfigModified = true;
                  };

                  linkField.appendChild(input);
                  linkField.appendChild(deleteLinkBtn);
                  linksContainer.appendChild(linkField);
                }
              }
            }
          });
        }

        config = loadedConfig;
        generateConfig();
      } catch (e) {
        document.getElementById('warnings').innerHTML = `Ошибка загрузки конфигурации: ${e.message}`;
      }
    }

    // Переключение темы
    function toggleTheme() {
      document.body.classList.toggle('dark-theme');
    }

    // Копирование конфигурации в буфер обмена
    async function copyConfigToClipboard() {
      try {
        const output = document.getElementById('output');
        const configText = output.textContent;
        await navigator.clipboard.writeText(configText);

        const copyTooltip = document.getElementById('copyTooltip');
        copyTooltip.classList.add('show');
        setTimeout(() => {
          copyTooltip.classList.remove('show');
        }, 2000);
      } catch (err) {
        console.error('Ошибка копирования:', err);
        alert('Не удалось скопировать конфигурацию');
      }
    }

    // Адаптация размера контейнера вывода
    function resizeOutputContainer() {
      const container = document.getElementById('configDisplay');
      if (!container || container.style.display === 'none') return;
      requestAnimationFrame(() => {
        container.style.height = 'auto';
        container.style.height = Math.min(container.scrollHeight, 600) + 'px';
      });
    }
  </script>
</body>
</html>
EOF

if [ -f "$LIGHTTPD_CONF_FILE" ]; then
    echo "[*] Удаление конфигурации Lighttpd..."
    rm "$LIGHTTPD_CONF_FILE"
fi

echo "[*] Создание конфигурации Lighttpd..."
cat > "$LIGHTTPD_CONF_FILE" << 'EOF'
server.port := 8096
server.username := ""
server.groupname := ""

$HTTP["host"] =~ "^(.+):8096$" {
    url.redirect = ( "^/xray/" => "http://%1:96" )
    url.redirect-code = 301
}

$SERVER["socket"] == ":96" {
    server.document-root = "/opt/share/www/"
    server.modules += ( "mod_cgi" )
    cgi.assign = ( ".php" => "/opt/bin/php8-cgi" )
    setenv.set-environment = ( "PATH" => "/opt/bin:/usr/bin:/bin" )
    index-file.names = ( "index.php" )
    url.rewrite-once = ( "^/(.*)" => "/xray/$1" )
}
EOF

echo "[*] Установка прав и перезапуск..."
ln -sf /opt/etc/init.d/S80lighttpd /opt/bin/lighttpd
chmod +x "$INDEX_FILE"
/opt/etc/init.d/S80lighttpd enable
/opt/etc/init.d/S80lighttpd stop
/opt/etc/init.d/S80lighttpd restart
echo "[*] Установка завершена."
echo "[*] Установщик веб панели удален."
rm "$0"
echo ""
echo "xray create @pegakmop installed"
echo ""
echo "Перейдите на http://<IP-роутера>:96"
echo ""
