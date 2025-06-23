<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    // 📦 Проверка и установка обновления интерфейса
    $currentVersion    = "0.0.0.4";
    $remoteVersionUrl  = "https://raw.githubusercontent.com/pegakmop/pegakmop.github.io/refs/heads/main/entware/sing-box-go-version.txt";
    $context           = stream_context_create(["http" => ["timeout" => 3]]);
    $remoteContent     = @file_get_contents($remoteVersionUrl, false, $context);

    // Проверка обновления
    if (isset($input['check_update'])) {
        $response = ['current' => $currentVersion, 'update_available' => false];

        if ($remoteContent !== false) {
            $lines = explode("\n", $remoteContent);
            $versionInfo = [];
            foreach ($lines as $line) {
                $parts = explode("=", trim($line), 2);
                if (count($parts) === 2) {
                    $versionInfo[trim($parts[0])] = trim($parts[1]);
                }
            }
            if (!empty($versionInfo["Version"])) {
                $response['latest']           = $versionInfo["Version"];
                $response['show']             = $versionInfo["Show"] ?? '';
                $response['update_available'] = version_compare($versionInfo["Version"], $currentVersion, ">");
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Неверный формат файла обновления.']);
                exit;
            }
        } else {
            http_response_code(500);
            echo json_encode(['error' => 'Не удалось получить информацию об обновлении.']);
            exit;
        }

        echo json_encode($response);
        exit;
    }

    // Запуск обновления интерфейса
    if (isset($input['run_update'])) {
        $out = shell_exec(
            'curl -sL "https://raw.githubusercontent.com/pegakmop/pegakmop.github.io/refs/heads/main/entware/sing-box-go-gen.php" '
          . '-o /opt/share/www/sing-box-go/index.php 2>&1'
        );
        echo json_encode([
            'message' => '✔ Веб интерфейс конфигуратора обновлён до актуальной версии, фиксы и баги устранены. Перезагружаю страницу...',
            'log'     => $out
        ]);
        exit;
    }

    // Повторная проверка IP (proxy)
    if (isset($input['check_only'])) {
        $externalIp = trim(shell_exec('curl -s myip.wtf'));
        sleep(1);
        $proxyIp    = trim(shell_exec('curl -s --interface t2s0 myip.wtf'));
        echo json_encode([
            'external_ip' => $externalIp,
            'proxy_ip'    => $proxyIp
        ]);
        exit;
    }

    // Установка конфига sing-box
    if (isset($input['config'])) {
        $configPath = '/opt/etc/sing-box/config.json';
            $configDir  = dirname($configPath);

    
    if (!is_dir($configDir)) {
        if (!mkdir($configDir, 0755, true)) {
            http_response_code(500);
            echo json_encode(['error' => 'Не удалось создать каталог для конфига.']);
            exit;
        }
    }

        $success    = file_put_contents($configPath, $input['config']);
        if ($success === false) {
            http_response_code(500);
            echo json_encode(['error' => 'Ошибка при сохранении файла.']);
            exit;
        }
        $restart    = shell_exec('/opt/etc/init.d/S99sing-box restart 2>&1');
        sleep(1);
        $status     = shell_exec('/opt/etc/init.d/S99sing-box status 2>&1');
        sleep(1);
        $externalIp = trim(shell_exec('curl -s myip.wtf'));
        sleep(1);
        $proxyIp    = trim(shell_exec('curl -s --interface t2s0 myip.wtf'));

        echo json_encode([
            'restart'     => $restart,
            'status'      => $status,
            'external_ip' => $externalIp,
            'proxy_ip'    => $proxyIp,
            'message'     => 'Конфиг успешно сохранён: /opt/etc/sing-box/config.json.'
        ]);
        exit;
    }

    // Установка интерфейса Proxy0
    if (isset($input['proxy_commands']) && is_array($input['proxy_commands'])) {
        $log = [];
        foreach ($input['proxy_commands'] as $cmd) {
            $out     = shell_exec($cmd . ' 2>&1');
            $log[]   = "» $cmd\n$out";
        }
        echo implode("\n", $log);
        exit;
    }
        // Отключение IPv6
    if (isset($input['disable_ipv6'])) {
        $script = <<<SH
#!/bin/sh
curl -kfsS http://localhost:79/rci/show/interface/ | jq -r '
  to_entries[] |
  select(.value.defaultgw == true or .value.via != null) |
  if .value.via then "\\(.value.id) \\(.value.via)" else "\\(.value.id)" end
' | while read -r iface via; do
  echo "⛔️ Отключаем IPv6 на \$iface..."
  ndmc -c "no interface \$iface ipv6 address"
  if [ -n "\$via" ]; then
    echo "⛔️ Отключаем IPv6 на \$via..."
    ndmc -c "no interface \$via ipv6 address"
  fi
done
echo "💾 Сохраняем конфигурацию..."
ndmc -c "system configuration save"
echo "✅ Готово. IPv6 отключён на нужных интерфейсах."
SH;

        $tmp = '/tmp/disable_ipv6.sh';
        file_put_contents($tmp, $script);
        chmod($tmp, 0755);
        $out = shell_exec("$tmp 2>&1");

        echo json_encode([
            'message' => '🛠 IPv6 отключён',
            'log'     => $out
        ]);
        exit;
    }

    // Неизвестный запрос
    http_response_code(400);
    echo "Ошибка: неизвестный формат запроса.";
    exit;
}
?>
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <title>Sing-box WebUI</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link
    href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
    rel="stylesheet"
  >
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css" rel="stylesheet">
</head>
<body class="bg-light">
  <div class="container mt-5">
    <div class="card shadow">
      <div class="card-body">
        <h3 class="card-title mb-4">Конфигуратор Sing-box</h3>

<div class="mb-3">
  <label for="router" class="form-label">
    IP роутера (local ip & public ip):
  </label>
  <input
    type="text"
    id="router"
    class="form-control"
    value=""
  >
</div>

<script>
window.addEventListener("DOMContentLoaded", () => {
  const routerInput = document.getElementById("router");

  if (routerInput && location.hostname.match(/^(\d{1,3}\.){3}\d{1,3}$/)) {
    // Только IP, без порта
    routerInput.value = location.hostname;
  } else {
    // Полный host с портом, если есть
    routerInput.value = "192.168.1.1";
  }
});
</script>

        <div class="mb-3">
          <label for="links" class="form-label">
            Прокси ссылки:
          </label>
          <textarea
            id="links"
            class="form-control"
            rows="8"
            placeholder="ss://, vless://, vmess://, trojan://, tuic:// и т.д. Каждый добавленный ключ должен быть с новой строки!"
          ></textarea>
        </div>

        <div class="form-check mb-3">
          <input
            class="form-check-input"
            type="checkbox"
            id="includeClashApi"
            checked
          >
          <label class="form-check-label" for="includeClashApi">
            Включить Clash API (веб-интерфейс)
          </label>
        </div>

        <div class="d-flex gap-2 mb-3">
          <button
            class="btn btn-primary"
            onclick="generateConfig()"
          >Сгенерировать config.json</button>
          <button
            id="pasteBtn"
            class="btn btn-outline-secondary btn-sm"
            onclick="pasteClipboard()"
          >📋 Вставить</button>
          <button
            id="updateBtn"
            class="btn btn-outline-danger d-none"
            onclick="runUpdate()"
          >⬇️ Обновить веб интерфейс</button>
        </div>

        <div class="d-flex gap-2 mb-3">
          <button
            id="proxyBtn"
            class="btn btn-info d-none"
            onclick="installProxy()"
          >🧩 Установить Proxy0</button>
          <button
            id="installBtn"
            class="btn btn-warning d-none"
            onclick="installConfig()"
          >📦 Установить config.json</button>
        </div>
        <button
  id="ipv6Btn"
  class="btn btn-danger d-none"
  onclick="disableIPv6()">🛠 Отключить IPv6 оставив only IPv4</button>
        <div id="warnings" class="text-danger mb-3"></div>

        <div id="resultWrapper" class="d-none">
          <h5>Результат:</h5>
          <pre
            id="result"
            class="bg-dark text-white p-3 rounded"
            style="white-space: pre-wrap;"
          ></pre>
          <div class="mt-2">
            <a
              id="downloadBtn"
              class="btn btn-success d-none"
              download="config.json"
            >⬇ Скачать config.json</a>
            <button
              id="copyBtn"
              class="btn btn-secondary d-none"
              onclick="copyConfig()"
            >Скопировать</button>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Модальное окно для установки -->
<div
  class="modal fade"
  id="installModal"
  tabindex="-1"
  aria-hidden="true"
>
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Установка на роутер</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">×</button>
      </div>
      <div class="modal-body">
        <pre
          id="installOutput"
          class="bg-light p-2 border rounded"
          style="white-space: pre-wrap;"
        >Ожидание...</pre>
        <div class="text-end mt-3">
          <button
            id="recheckBtn"
            class="btn btn-outline-primary d-none"
            onclick="recheckProxy()"
          >🔄 Повторная проверка IP</button>
        </div>
      </div>
    </div>
  </div>
</div>

  <script
    src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"
  ></script>
  <script>
    function getPostUrl() {
      return `${location.origin}/index.php`;
      alert(getPostUrl());
    }

    function pasteClipboard() {
      navigator.clipboard.readText()
        .then(text => {
          document.getElementById("links").value = text;
          document.getElementById("links").focus();
        })
        .catch(err => {
          alert("Не удалось получить текст из буфера обмена: " + err);
        });
    }

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
      } catch (e) {
        console.log("Ошибка парсинга SS:", e);
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
        const flow     = params.get("flow") || params.get("mode");
        const sni      = params.get("sni");
        const host     = params.get("host");
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
          config.transport = { type: transportType };
          if (transportType === "ws") {
            config.transport.path = params.get("path") || "/";
            if (host) config.transport.headers = { Host: host };
          } else if (transportType === "grpc" && params.get("path")) {
            config.transport.serviceName = params.get("path");
          }
        }

        if (flow && transportType !== "grpc") {
          config.flow = flow;
        }

        return config;
      } catch (e) {
        console.log("Ошибка парсинга VLESS:", e);
        return null;
      }
    }

    function parseVMess(line) {
      try {
        const raw = line.replace("vmess://", "");
        const obj = JSON.parse(atob(raw));
        return {
          type: "vmess",
          tag: obj.ps || "VMess",
          server: obj.add,
          server_port: parseInt(obj.port),
          uuid: obj.id,
          security: obj.security || "auto",
          tls: obj.tls === "tls",
          transport: {
            type: obj.net || "tcp",
            path: obj.path || "/"
          }
        };
      } catch (e) {
        console.log("Ошибка парсинга VMess:", e);
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
      } catch (e) {
        console.log("Ошибка парсинга Trojan:", e);
        return null;
      }
    }

    function parseTUIC(line) {
      try {
        const url = new URL(line);
        const tag = decodeURIComponent(url.hash.slice(1)) || "TUIC";
        const [uuid, password] = url.username.includes(':')
          ? url.username.split(':')
          : [url.username, url.password];
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
      } catch (e) {
        console.log("Ошибка парсинга TUIC:", e);
        return null;
      }
    }

    function generateConfig() {
      const routerIp       = document.getElementById("router").value.trim();
      const proxyLinks     = document.getElementById("links").value.trim().split('\n').filter(l => l.trim());
      const includeClash   = document.getElementById("includeClashApi").checked;
      const resultDiv      = document.getElementById("result");
      const warningsDiv    = document.getElementById("warnings");
      const downloadLink   = document.getElementById("downloadBtn");
      const copyBtn        = document.getElementById("copyBtn");
      const resultWrapper  = document.getElementById("resultWrapper");

      warningsDiv.innerHTML = '';
      resultWrapper.classList.add("d-none");
      downloadLink.classList.add("d-none");
      copyBtn.classList.add("d-none");

      if (!routerIp) {
        warningsDiv.innerHTML = "Ошибка: IP роутера обязателен";
        return;
      }
      if (proxyLinks.length === 0) {
        warningsDiv.innerHTML = "Ошибка: нужно хотя бы одну ссылку";
        return;
      }

      const outbounds = [];
      const tags      = [];
      const warns     = [];

      proxyLinks.forEach(line => {
        let cfg = null;
        if (line.startsWith("ss://"))      cfg = parseSS(line);
        else if (line.startsWith("vless://")) cfg = parseVLESS(line);
        else if (line.startsWith("vmess://")) cfg = parseVMess(line);
        else if (line.startsWith("trojan://")) cfg = parseTrojan(line);
        else if (line.startsWith("tuic://"))   cfg = parseTUIC(line);

        if (cfg) {
          outbounds.push(cfg);
          if (["vless","vmess","trojan","tuic"].includes(cfg.type)) {
            tags.push(cfg.tag);
          }
        } else {
          warns.push(`Не удалось распарсить: ${line}`);
        }
      });

      if (tags.length) {
        outbounds.unshift({
          type: "selector",
          tag: "select",
          outbounds: tags,
          default: tags[0],
          interrupt_exist_connections: false
        });
      }
      outbounds.push(
        { type: "direct", tag: "direct" },
        { type: "block",  tag: "block"  }
      );

      const config = {
        experimental: { cache_file: { enabled: true } },
        log: { level: "debug", timestamp: true },
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
          final: tags.length ? "select" : "direct",
          rules: [
            { protocol: "dns", outbound: "dns-out" },
            { network: "udp", port: 443, outbound: "block" }
          ]
        }
      };

      if (includeClash) {
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

      if (warns.length) {
        warningsDiv.innerHTML = warns.map(w => `– ${w}`).join("<br>");
      }
    }

    function copyConfig() {
      const text = document.getElementById("result").textContent;
      navigator.clipboard.writeText(text)
        .then(() => alert("Конфиг скопирован в буфер!"))
        .catch(e => alert("Ошибка копирования: " + e));
    }

    function installConfig() {
      const resultDiv = document.getElementById("result");
      const cfg       = resultDiv.textContent;
        if (!cfg) {
          alert("❗️Ошибка установки config.json на роутер, нужно заполнить хотя бы одну прокси ссылку и нажать снова сгенерировать config.json и после уже нажать установить config.json");
          return;
        }

      const modal     = new bootstrap.Modal(document.getElementById('installModal'));
      const out       = document.getElementById("installOutput");
      out.textContent = "📦 Отправка конфига на роутер...";
      modal.show();

      fetch(getPostUrl(), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ config: cfg })
      })
      .then(async res => {
        if (!res.ok) {
          const err = await res.text();
          out.textContent += `\n❌ Ошибка:\n${err}`;
          return;
        }
        const data = await res.json();
        out.textContent += "\n✅ Ответ роутера:\n" + data.message +
                           "\n🚀 Перезапускаем sing-box:\n" + data.restart +
                           "\n📟 Статус:\n" + data.status +
                           "\n🌐 Внешний IP: " + data.external_ip +
                           "\n🛡️ Proxy IP: " + data.proxy_ip +
                           ((data.proxy_ip && data.proxy_ip !== data.external_ip)
                             ? "\n🎯 Прокси работает!"
                             : "\n❌ Прокси не работает") +
                           "\n🎉 Установка завершена!";
        document.getElementById("recheckBtn").classList.remove("d-none");
      })
      .catch(e => out.textContent += "\n❌ Ошибка запроса:\n" + e);
    }

    function installProxy() {
      const routerIp = document.getElementById("router").value.trim();
      const modal    = new bootstrap.Modal(document.getElementById('installModal'));
      const out      = document.getElementById("installOutput");
      out.textContent = "⏳Установка Proxy0...";
      modal.show();
      const cmds = [
        'ndmc -c "no interface Proxy0" >/dev/null 2>&1',
        'ndmc -c "system configuration save" >/dev/null 2>&1',
        'ndmc -c "interface Proxy0" >/dev/null 2>&1',
        `ndmc -c "interface Proxy0 description Sing-Box-Proxy0-${routerIp}:1080" >/dev/null 2>&1`,
        'ndmc -c "interface Proxy0 proxy protocol socks5" >/dev/null 2>&1',
        `ndmc -c "interface Proxy0 proxy upstream ${routerIp} 1080" >/dev/null 2>&1`,
        'ndmc -c "interface Proxy0 up" >/dev/null 2>&1',
        'ndmc -c "interface Proxy0 ip global 1" >/dev/null 2>&1',
        'ndmc -c "system configuration save" >/dev/null 2>&1',
        'sleep 2',
        'ndmc -c "show interface Proxy0"',
        'curl -s --interface t2s0 myip.wtf',
        'Установка прокси завершена, установите конфиг >/dev/null 2>&1'
      ];
      fetch(getPostUrl(), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ proxy_commands: cmds })
      })
      .then(res => res.text())
      .then(txt => out.textContent += "\n⌛️ Состояние установки прокси:\n" + "✅  Proxy0 установка завершена.")
      // либо выше закомментировать, а ниже рас комментировать строку: .then(txt => out.textContent +=  для видимости полных логов, либо наоборот чтобы не было логов.
     // .then(txt => out.textContent += "\n⌛️Состояние установки прокси:\n" + txt)
      .catch(e => out.textContent += "\n❌ Ошибка:\n" + e);
    }

    function recheckProxy() {
      const out = document.getElementById("installOutput");
      out.textContent += "\n🔄 Повторная проверка IP…";
      fetch(getPostUrl(), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ check_only: true })
      })
      .then(res => res.json())
      .then(d => {
        out.textContent += `\n🌐 Внешний IP: ${d.external_ip}` +
                           `\n🛡️ Proxy IP: ${d.proxy_ip}` +
                           ((d.proxy_ip && d.proxy_ip !== d.external_ip)
                             ? "\n🎯 Прокси работает!"
                             : "\n❌ Прокси не работает");
      })
      .catch(e => out.textContent += "\n❌ Ошибка проверки:\n" + e);
    }
    
    function disableIPv6() {
  const modal = new bootstrap.Modal(document.getElementById('installModal'));
  const out   = document.getElementById("installOutput");
  out.textContent = "⏳ Отключение IPv6...";
  modal.show();

  fetch(getPostUrl(), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ disable_ipv6: true })
  })
  .then(res => res.json())
  .then(d => {
    out.textContent += "\n" + d.message + "\n\n" + d.log;
  })
  .catch(e => {
    out.textContent += "\n❌ Ошибка: " + e;
  });
}

    function runUpdate() {
      fetch(getPostUrl(), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ run_update: true })
      })
      .then(res => res.json())
      .then(d => { alert(d.message); location.reload(); })
      .catch(e => alert("❌ Ошибка обновления: " + e));
    }

    function checkUpdate(manual = true) {
      const btn = document.getElementById("updateBtn");
      fetch(getPostUrl(), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ check_update: true })
      })
      .then(res => res.json())
      .then(d => {
        if (d.update_available) {
          btn.classList.remove("d-none");
          btn.textContent = `⬇️ Обновить до v${d.latest}`;
          btn.title = d.show || "";
          if (manual && confirm(`Доступна новая версия ${d.latest}\n${d.show}\nОбновить?`)) {
            runUpdate();
          }
        } else {
          btn.classList.add("d-none");
          if (manual) alert("✅ Вы уже на последней версии.");
        }
      })
      .catch(e => {
        if (manual) alert("❌ Ошибка проверки: " + e);
        else console.warn("Ошибка авто-проверки:", e);
      });
    }

    // Чтобы после генерации сразу появились кнопки установки
    const origGen = generateConfig;
    generateConfig = function() {
      origGen();
      document.getElementById("installBtn").classList.remove("d-none");
      document.getElementById("proxyBtn").classList.remove("d-none");
        document.getElementById("ipv6Btn").classList.remove("d-none");
    };

    window.addEventListener("DOMContentLoaded", () => {
      const routerField = document.getElementById("router");
      const pasteBtn    = document.getElementById("pasteBtn");
      if (location.protocol !== "https:") pasteBtn?.classList.add("d-none");
      // Авто-проверка обновлений без модалов
      setTimeout(() => checkUpdate(false), 1000);
    });
  </script>
</body>
</html>
