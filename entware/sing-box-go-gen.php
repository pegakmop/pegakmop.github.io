<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    // 🔁 Повторная проверка IP
    if (isset($input['check_only'])) {
        $externalIp = trim(shell_exec('curl -s myip.wtf'));
        sleep(1);
        $proxyIp = trim(shell_exec('curl -s --interface t2s0 myip.wtf'));
        echo json_encode([
            'external_ip' => $externalIp,
            'proxy_ip' => $proxyIp
        ]);
        exit;
    }

    // 📦 Установка конфига Sing-box
    if (isset($input['config'])) {
        $configPath = '/opt/etc/sing-box/config.json';
        $success = file_put_contents($configPath, $input['config']);

        if ($success === false) {
            http_response_code(500);
            echo json_encode(['error' => 'Ошибка при сохранении файла.']);
            exit;
        }

        $restart = shell_exec('/opt/etc/init.d/S99sing-box restart 2>&1');
        sleep(1);
        $status = shell_exec('/opt/etc/init.d/S99sing-box status 2>&1');
        sleep(1);
        $externalIp = trim(shell_exec('curl -s myip.wtf'));
        sleep(1);
        $proxyIp = trim(shell_exec('curl -s --interface t2s0 myip.wtf'));

        echo json_encode([
            'restart' => $restart,
            'status' => $status,
            'external_ip' => $externalIp,
            'proxy_ip' => $proxyIp,
            'message' => 'Конфиг успешно сохранён: /opt/etc/sing-box/config.json.'
        ]);
        exit;
    }

    // 🧩 Установка интерфейса Proxy0
    if (isset($input['proxy_commands']) && is_array($input['proxy_commands'])) {
        $log = [];
        foreach ($input['proxy_commands'] as $cmd) {
            $out = shell_exec($cmd . ' 2>&1');
            $log[] = "» $cmd\n$out";
        }
        echo implode("\n", $log);
        exit;
    }

    http_response_code(400);
    echo "Ошибка: неизвестный формат запроса.";
    exit;
}
?>
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <title>Генератор конфига для sing-box</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
  <div class="container mt-5">
    <div class="card shadow">
      <div class="card-body">
        <h3 class="card-title mb-4">Генератор конфига для sing-box</h3>

        <div class="mb-3">
          <label for="router" class="form-label">Адрес роутера:</label>
          <input type="text" id="router" class="form-control" placeholder="например: 192.168.1.1">
        </div>

        <div class="mb-3">
          <label for="links" class="form-label">Вставьте ссылки:</label>
          <textarea id="links" class="form-control" rows="8" placeholder="ss://, vless://, vmess:// и др. ссылки, одна на строку"></textarea>
        </div>

        <div class="mb-3 form-check">
          <input type="checkbox" id="includeClashApi" class="form-check-input" checked>
          <label for="includeClashApi" class="form-check-label">Включить clash_api (для веб-интерфейса)</label>
        </div>


<script>
window.addEventListener("DOMContentLoaded", () => {
  const routerField = document.getElementById("router");
  const pasteBtn = document.getElementById("pasteBtn");

  // Установка значения по умолчанию
  if (!routerField.value) {
    routerField.value = "192.168.1.1";
  }

  // Скрытие кнопки "Вставить", если страница не по HTTPS
  if (location.protocol !== "https:") {
    pasteBtn?.classList.add("d-none");
  }
});
</script>

<div class="d-flex gap-2 mb-4">
  <button class="btn btn-primary" onclick="generateConfig()">Сгенерировать config.json</button>
  <button id="pasteBtn" class="btn btn-outline-secondary btn-sm" onclick="pasteClipboard()">📋 Вставить</button>
</div>
<div class="d-flex gap-2 mb-4">
   <button id="proxyBtn" class="btn btn-info d-none" onclick="installProxy()">🧩 Установить прокси-интерфейс</button>
   <button id="installBtn" class="btn btn-warning d-none" onclick="installConfig()">📦 Установить конфиг на роутер</button>
</div>
<div class="d-flex gap-2 mb-4">
  <a id="downloadBtn" class="btn btn-success d-none" download="config.json">⬇ Скачать config.json</a>
  <button id="copyBtn" class="btn btn-secondary d-none" onclick="copyConfig()">Скопировать содержимое</button>
</div>

        <div id="warnings" class="text-danger mb-3"></div>

        <div id="resultWrapper" class="d-none">
          <h5>Результат:</h5>
          <pre id="result" class="bg-dark text-white p-3 rounded" style="white-space: pre-wrap;"></pre>
        </div>
      </div>
    </div>
  </div>
<div class="modal fade" id="installModal" tabindex="-1" aria-labelledby="installModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="installModalLabel">Установка на роутер</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Закрыть"></button>
      </div>
<div class="modal-body">
  <pre id="installOutput" class="bg-light p-2 border rounded" style="white-space: pre-wrap;">Отправка конфига...</pre>
  <div class="text-end mt-3">
    <button id="recheckBtn" class="btn btn-outline-primary d-none" onclick="recheckProxy()">🔄 Проверить состояние подключения прокси повторно</button>
  </div>
</div>
    </div>
  </div>
</div>
<script>
  function pasteClipboard() {
    navigator.clipboard.readText()
      .then(text => {
        const textarea = document.getElementById("links");
        textarea.value = text;
        textarea.focus();
      })
      .catch(err => {
        alert("Не удалось получить текст из буфера обмена: " + err);
      });
  }
</script>
  <script>
    function parseSS(line) {
      try {
        const url = new URL(line);
        const [authPart, serverPart] = url.href.replace("ss://", "").split('@');
        let decoded;
        try {
          decoded = atob(authPart);
        } catch {
          decoded = decodeURIComponent(authPart);
        }
        const [method, password] = decoded.split(':');
        const [server, port = "8388"] = serverPart.split(':');

        const tag = decodeURIComponent(url.hash.slice(1)) || 
                   (url.search.includes("outline=1") ? "Outline" : "ShadowSocks");

        return {
          type: "shadowsocks",
          tag,
          server,
          server_port: parseInt(port),
          method,
          password
        };
      } catch (error) {
        console.log(`Ошибка парсинга SS: ${error.message}`);
        return null;
      }
    }

    function parseVLESS(line) {
      try {
        const url = new URL(line);
        const [uuid, serverPort] = url.href.replace("vless://", "").split('@');
        const [server, port] = serverPort.split(':');
        const params = new URLSearchParams(url.search);

        const tag = decodeURIComponent(url.hash.slice(1)) || "VLESS";
        const security = params.get("security") || "none";
        const flow = params.get("flow") || params.get("mode");
        const sni = params.get("sni");
        const host = params.get("host");
        const transportType = params.get("type") || "ws";

        const config = {
          type: "vless",
          tag,
          server,
          server_port: parseInt(port),
          uuid,
          packet_encoding: "xudp"
        };

        if (security !== "none") {
          config.tls = {
            enabled: true,
            server_name: sni || server,
            insecure: false,
            utls: {
              enabled: true,
              fingerprint: params.get("fp") || "chrome"
            }
          };

          if (security === "reality") {
            config.tls.reality = {
              enabled: true,
              public_key: params.get("pbk") || "",
              short_id: params.get("sid") || ""
            };
          }
        }

        if (security !== "reality") {
          config.transport = {
            type: transportType
          };

          if (transportType === "ws") {
            config.transport.path = params.get("path") || "/";
            if (host) {
              config.transport.headers = { Host: host };
            }
          } else if (transportType === "grpc" && params.get("path")) {
            config.transport.serviceName = params.get("path");
          }
        }

        if (flow && transportType !== "grpc") {
          config.flow = flow;
        }

        return config;
      } catch (error) {
        console.log(`Ошибка парсинга VLESS: ${error.message}`);
        return null;
      }
    }

    function parseVMess(line) {
      try {
        const raw = line.replace("vmess://", "");
        const json = JSON.parse(atob(raw));
        
        return {
          type: "vmess",
          tag: json.ps || "VMess",
          server: json.add,
          server_port: parseInt(json.port),
          uuid: json.id,
          security: json.security || "auto",
          tls: json.tls === "tls",
          transport: {
            type: json.net || "tcp",
            path: json.path || "/"
          }
        };
      } catch (error) {
        console.log(`Ошибка парсинга VMess: ${error.message}`);
        return null;
      }
    }

    function parseTrojan(line) {
      try {
        const url = new URL(line);
        const [password, hostPort] = url.href.replace("trojan://", "").split('@');
        const [server, port] = hostPort.split(':');
        
        return {
          type: "trojan",
          tag: decodeURIComponent(url.hash.slice(1)) || "Trojan",
          server,
          server_port: parseInt(port),
          password,
          tls: {
            enabled: true,
            server_name: url.searchParams.get("sni") || server,
            insecure: false
          }
        };
      } catch (error) {
        console.log(`Ошибка парсинга Trojan: ${error.message}`);
        return null;
      }
    }

    function parseTUIC(line) {
      try {
        const url = new URL(line);
        const tag = decodeURIComponent(url.hash.slice(1)) || "TUIC";
        const [uuid, password] = url.username.includes(':') ? 
          url.username.split(':') : [url.username, url.password];
        
        return {
          type: "tuic",
          tag,
          server: url.hostname,
          server_port: parseInt(url.port),
          uuid,
          password,
          alpn: ["h3"],
          tls: {
            enabled: true,
            server_name: url.hostname,
            insecure: false
          }
        };
      } catch (error) {
        console.log(`Ошибка парсинга TUIC: ${error.message}`);
        return null;
      }
    }

    function generateConfig() {
      const routerIp = document.getElementById("router").value.trim();
      const proxyLinks = document.getElementById("links").value.trim().split('\n').filter(line => line.trim());
      const includeClashApi = document.getElementById("includeClashApi").checked;
      const resultDiv = document.getElementById("result");
      const warningsDiv = document.getElementById("warnings");
      const downloadLink = document.getElementById("downloadBtn");
      const copyBtn = document.getElementById("copyBtn");
      const resultWrapper = document.getElementById("resultWrapper");

      if (!routerIp) {
        warningsDiv.innerHTML = "Ошибка: Параметр routerIp обязателен";
        resultWrapper.classList.add("d-none");
        downloadLink.classList.add("d-none");
        copyBtn.classList.add("d-none");
        return;
      }

      if (proxyLinks.length === 0) {
        warningsDiv.innerHTML = "Ошибка: Необходимо указать хотя бы одну прокси ссылку";
        resultWrapper.classList.add("d-none");
        downloadLink.classList.add("d-none");
        copyBtn.classList.add("d-none");
        return;
      }

      const outbounds = [];
      const tags = [];
      const warnings = [];

      for (const line of proxyLinks) {
        const cleanLine = line.trim();
        if (!cleanLine) continue;

        let outbound = null;

        if (cleanLine.startsWith("ssconf://")) {
          warnings.push(`${cleanLine} (Outline 2.0 — не поддерживается)`);
          continue;
        }

        if (cleanLine.startsWith("ss://")) {
          outbound = parseSS(cleanLine);
        } else if (cleanLine.startsWith("vless://")) {
          outbound = parseVLESS(cleanLine);
        } else if (cleanLine.startsWith("vmess://")) {
          outbound = parseVMess(cleanLine);
        } else if (cleanLine.startsWith("trojan://")) {
          outbound = parseTrojan(cleanLine);
        } else if (cleanLine.startsWith("tuic://")) {
          outbound = parseTUIC(cleanLine);
        }

        if (outbound) {
          outbounds.push(outbound);
          if (["vless", "vmess", "trojan", "tuic"].includes(outbound.type)) {
            tags.push(outbound.tag);
          }
        } else {
          warnings.push(`Не удалось распарсить: ${cleanLine}`);
        }
      }

      if (tags.length > 0) {
        outbounds.unshift({
          type: "selector",
          tag: "select",
          outbounds: tags,
          default: tags[0],
          interrupt_exist_connections: false
        });
      }

      outbounds.push(
        {
          type: "direct",
          tag: "direct"
        },
        {
          type: "block",
          tag: "block"
        }
      );

      const config = {
        experimental: {
          cache_file: { enabled: true }
        },
        log: { 
          level: "debug",
          timestamp: true
        },
        inbounds: [
          {
            type: "tun",
            interface_name: "tun0",
            domain_strategy: "ipv4_only",
            address: "172.16.250.1/30",
            auto_route: false,
            strict_route: false,
            sniff: true,
            sniff_override_destination: false
          },
          {
            type: "mixed",
            tag: "mixed-in",
            listen: "0.0.0.0",
            listen_port: 1080,
            sniff: true,
            sniff_override_destination: false
          }
        ],
        outbounds,
        route: { 
          auto_detect_interface: false,
          final: tags.length > 0 ? "select" : "direct",
          rules: [
            {
              protocol: "dns",
              outbound: "dns-out"
            },
            {
              network: "udp",
              port: 443,
              outbound: "block"
            }
          ]
        }
      };

      if (includeClashApi) {
        config.experimental.clash_api = {
          external_controller: `${routerIp}:9090`,
          external_ui: "ui",
          access_control_allow_private_network: true
        };
      }

      const jsonStr = JSON.stringify(config, null, 2);
      resultDiv.textContent = jsonStr;
      resultWrapper.classList.remove("d-none");

      const blob = new Blob([jsonStr], { type: "application/json" });
      downloadLink.href = URL.createObjectURL(blob);
      downloadLink.classList.remove("d-none");
      copyBtn.classList.remove("d-none");

      warningsDiv.innerHTML = warnings.length > 0 
        ? "Некорректные или неподдерживаемые ссылки:<br>" + warnings.map(x => `– ${x}`).join("<br>")
        : "";
    }

    function copyConfig() {
      const resultDiv = document.getElementById("result");
      const text = resultDiv.textContent;
      navigator.clipboard.writeText(text).then(() => {
        alert("Конфигурация скопирована в буфер обмена!");
      }).catch(err => {
        console.error("Ошибка копирования:", err);
        alert("Не удалось скопировать конфигурацию");
      });
    }
  </script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
// 👇 Добавляем функцию для определения URL
function getPostUrl(routerIp) {
  const isIp = /^\d{1,3}(\.\d{1,3}){3}$/.test(location.hostname);
  return isIp ? `http://${routerIp}:94/index.php` : `index.php`;
}

function installConfig() {
  const resultDiv = document.getElementById("result");
  const configJson = resultDiv.textContent;
  const routerIp = document.getElementById("router").value.trim();
  const modal = new bootstrap.Modal(document.getElementById('installModal'));
  const output = document.getElementById("installOutput");

  output.textContent = "📦 Отправка конфига на роутер...";
  modal.show();

  fetch(getPostUrl(routerIp), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ config: configJson })
  })
  .then(async response => {
    if (!response.ok) {
      const error = await response.text();
      output.textContent += `\n❌ Ошибка:\n${error}`;
      return;
    }

    const data = await response.json();

    output.textContent += "\n✅ Ответ роутера:\n";
    output.textContent += `\n${data.message}\n`;
    output.textContent += `\n🚀 Перезапускаем sing-box:\n${data.restart}`;
    output.textContent += `\n📟 Статус запуска sing-box:\n${data.status}`;
    output.textContent += `\n🌐 Внешний IP: ${data.external_ip}`;
    output.textContent += `\n🛡️  IP через прокси: ${data.proxy_ip}`;

    if (data.proxy_ip && data.proxy_ip !== data.external_ip) {
      output.textContent += "\n🎯 Прокси работает (IP адреса отличаются)";
    } else {
      output.textContent += "\n❌ Прокси не работает (IP адреса совпадают либо нет ответа от сервера) \n🔄 Нажмите кнопку проверить состояние прокси повторно.";
    }

    output.textContent += "\n🎉 Установка завершена!\n";
    document.getElementById("recheckBtn").classList.remove("d-none");
  })
  .catch(err => {
    output.textContent += `\n❌ Ошибка запроса:\n${err}`;
  });
}

function installProxy() {
  const routerIp = document.getElementById("router").value.trim();
  const modal = new bootstrap.Modal(document.getElementById('installModal'));
  const output = document.getElementById("installOutput");

  output.textContent = "🧩 Отправка команды на установку Proxy0...";
  modal.show();

  const commands = [
    'ndmc -c "no interface Proxy0"',
    'ndmc -c "interface Proxy0"',
    `ndmc -c "interface Proxy0 description Sing-box-proxy-${routerIp}:1080"`,
    'ndmc -c "interface Proxy0 proxy connect via br0"',
    'ndmc -c "interface Proxy0 proxy protocol socks5"',
    `ndmc -c "interface Proxy0 proxy upstream ${routerIp} 1080"`,
    'ndmc -c "interface Proxy0 up"',
    'ndmc -c "interface Proxy0 ip global 1"',
    'sleep 2',
    'ndmc -c "show interface Proxy0"'
  ];

  fetch(getPostUrl(routerIp), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ proxy_commands: commands })
  })
  .then(res => res.text())
  .then(text => {
    output.textContent += `\n✅ Ответ от роутера:\n${text}`;
  })
  .catch(err => {
    output.textContent += `\n❌ Ошибка отправки:\n${err}`;
  });
}

function recheckProxy() {
  const routerIp = document.getElementById("router").value.trim();
  const output = document.getElementById("installOutput");

  output.textContent += "\n\n🔄 Повторная проверка IP...";

  fetch(getPostUrl(routerIp), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ check_only: true })
  })
  .then(res => res.json())
  .then(data => {
    output.textContent += `\n🌐 Внешний IP: ${data.external_ip}`;
    output.textContent += `\n🛡️  Прокси IP: ${data.proxy_ip}`;

    if (data.proxy_ip && data.proxy_ip !== data.external_ip) {
      output.textContent += "\n🎯 Прокси работает (IP адреса отличаются)";
    } else {
      output.textContent += "\n❌ Прокси не работает (IP адреса совпадают либо нет ответа от сервера)";
    }
  })
  .catch(err => {
    output.textContent += `\n❌ Ошибка повторной проверки:\n${err}`;
  });
}

// 👇 Обновляем generateConfig
const originalGenerateConfig = generateConfig;
generateConfig = function () {
  originalGenerateConfig();
  document.getElementById("installBtn").classList.remove("d-none");
  document.getElementById("proxyBtn").classList.remove("d-none");
};
</script>
</body>
</html>
