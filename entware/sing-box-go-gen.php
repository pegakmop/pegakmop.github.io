<?php
/* ======================= BACKEND: sing-box only ======================= */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    header('Content-Type: application/json; charset=utf-8');

    $input = file_get_contents('php://input');

    $respond = function(string $status, array $payload = [], int $http_code = 200) {
        http_response_code($http_code);
        echo json_encode(array_merge(['status' => $status], $payload), JSON_UNESCAPED_UNICODE);
        exit;
    };

    if (!$input) {
        $respond('error', ['error'=>'empty_request','message'=>'Пустой запрос'], 400);
    }

    // 0) Путь и команда рестарта под sing-box
    $path   = '/opt/etc/sing-box/config.json';
    $rc_cmd = '/opt/etc/init.d/S99sing-box restart';

    // 1) Каталог для конфига
    $dir = dirname($path);
    if (!is_dir($dir)) {
        if (!@mkdir($dir, 0755, true) && !is_dir($dir)) {
            $respond('error', ['error'=>'mkdir_failed','message'=>"Не удалось создать каталог: {$dir}"], 500);
        }
    }
    if (!is_writable($dir)) {
        $respond('error', ['error'=>'dir_not_writable','message'=>"Нет прав на запись в каталог: {$dir}"], 500);
    }

    // 2) Проверка системного компонента proxy (чтобы руками не ставили)
    $proxyOk = false;
    for ($i = 0; $i < 3; $i++) {
        $out   = shell_exec('ndmc -c "components list" 2>&1') ?? '';
        $lines = preg_split('/\r?\n/', $out) ?: [];
        foreach ($lines as $idx => $line) {
            if (stripos($line, 'name: proxy') !== false) {
                $slice = array_slice($lines, $idx, 16);
                foreach ($slice as $sl) {
                    if (stripos($sl, 'installed:') !== false) { $proxyOk = true; break 2; }
                }
            }
        }
        if ($proxyOk) break;
        usleep(1111111); // ~1.11s
    }
    if (!$proxyOk) {
        $log = [];
        foreach ([
            'ndmc -c components',
            'ndmc -c "components install proxy"',
            'ndmc -c "components commit"',
            'ndmc -c "system configuration save"',
        ] as $c) {
            $log[] = ['cmd'=>$c, 'output'=>shell_exec($c.' 2>&1')];
        }
        $respond('action_required', [
            'step'=>'proxy_component',
            'message'=>"Компонент «proxy» не установлен. Я добавил его в установщик. ".
                       "Зайдите в веб-интерфейс Keenetic → Параметры системы → Изменить набор компонентов → Обновить KeeneticOS, ".
                       "подтвердите установку и повторите попытку.",
            'logs'=>$log
        ]);
    }

    // 3) IP роутера для описаний
    $host = trim(shell_exec("ip -4 -o addr show br0 2>/dev/null | awk '{print \$4}' | cut -d/ -f1 | head -n1"));
    if ($host === '' || $host === null) $host = '192.168.1.1';

    // 4) Сохраняем конфиг
    if (file_put_contents($path, $input) === false) {
        $respond('error', ['step'=>'write_config','message'=>'Не удалось записать конфиг','path'=>$path], 500);
    }

    // 5) ndmc-интерфейсы под каждый inbound (sing-box: tag + listen_port)
    $interfaces = [];
    $cfg = json_decode($input, true);
    if (isset($cfg['inbounds']) && is_array($cfg['inbounds'])) {
        foreach ($cfg['inbounds'] as $inb) {
            $tag  = $inb['tag'] ?? null;                // e.g. "proxy2"
            $port = isset($inb['listen_port']) ? (int)$inb['listen_port'] : null; // e.g. 1083
            if (!$tag || !$port) continue;

            preg_match('/(\d+)$/', (string)$tag, $m);
            $n = $m[1] ?? '0';
            $ifName = "Proxy{$n}";

            $cmds = [
                "ndmc -c \"no interface {$ifName}\"",
                "ndmc -c \"interface {$ifName}\"",
                "ndmc -c \"interface {$ifName} description NeoFit-sing-box-{$tag}-{$ifName}-{$host}:{$port}\"",
                "ndmc -c \"interface {$ifName} proxy protocol socks5\"",
                "ndmc -c \"interface {$ifName} proxy socks5-udp\"",
                "ndmc -c \"interface {$ifName} proxy upstream {$host} {$port}\"",
                "ndmc -c \"interface {$ifName} up\"",
                "ndmc -c \"interface {$ifName} ip global 1\""
            ];

            $cmdLogs = [];
            foreach ($cmds as $c) {
                $out = []; $code = 0;
                exec($c . ' 2>&1', $out, $code);
                $cmdLogs[] = ['cmd'=>$c, 'exit_code'=>$code, 'output'=>implode("\n", $out)];
            }

            $interfaces[] = [
                'interface' => $ifName,
                'tag'       => $tag,
                'port'      => $port,
                'upstream'  => ['host'=>$host, 'port'=>$port],
                'logs'      => $cmdLogs
            ];
        }
        // фиксируем конфиг роутера
        $saveCfgOut = []; $saveCfgCode = 0;
        exec('ndmc -c "system configuration save" 2>&1', $saveCfgOut, $saveCfgCode);
    }

    // 6) Рестарт sing-box
    $out2 = []; $code2 = 0;
    exec($rc_cmd . ' 2>&1', $out2, $code2);
    $ok = ($code2 === 0);

    // 7) Ответ
    $cnt = count($interfaces);
    $respond($ok ? 'ok' : 'warning', [
        'message' => $ok
            ? "✅ Конфиг сохранён".($cnt ? ", интерфейсы добавлены ({$cnt})" : ", интерфейсы не найдены").", sing-box перезапущен"
            : "⚠️ Конфиг сохранён".($cnt ? ", интерфейсы добавлены ({$cnt})" : ", интерфейсы не найдены").", но sing-box не перезапустился",
        'write_config'   => ['ok'=>true, 'path'=>$path],
        'interfaces'     => ['count'=>$cnt, 'upstream_host'=>$host, 'items'=>$interfaces],
        'service_restart'=> ['ok'=>$ok, 'cmd'=>$rc_cmd, 'exit_code'=>$code2, 'output'=>implode("\n",$out2)]
    ]);
    exit;
}
?>
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <title>NeoFit sing-box</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/styles/atom-one-dark.min.css">
  <style>
    *,*::before,*::after{box-sizing:border-box}
    body{--bg:#1e1e1e;--fg:#c9d1d9;--border:#555;--card:#282c34;--btn:#444;--btnfg:#fff;
         margin:0;padding:20px;font-family:Arial,Helvetica,sans-serif;background:var(--bg);color:var(--fg)}
    h1{text-align:center;margin:0 0 24px}
    .controls{display:flex;gap:10px;flex-wrap:wrap;justify-content:center;margin-bottom:16px}
    button{background:var(--btn);color:var(--btnfg);border:none;border-radius:20px;padding:10px 16px;cursor:pointer}
    .interface-container{border:1px solid var(--border);background:var(--card);padding:10px;margin-bottom:10px;border-radius:6px}
    .interface-header{display:flex;gap:8px;align-items:center;margin-bottom:8px}
    input[type="text"]{width:100%;padding:8px;border:1px solid var(--border);border-radius:4px;background:var(--card);color:var(--fg)}
    .link-field{display:flex;gap:8px;margin-bottom:8px}
    .config-display{border:1px solid var(--border);background:var(--card);padding:10px;border-radius:6px;max-height:60vh;overflow:auto}
    #warnings{color:#ff6b6b;margin-top:8px}
  </style>
</head>
<body>
  <h1>NeoFit sing-box</h1>

  <div class="controls">
    <button><a href="https://yoomoney.ru/to/410012481566554" style="color:inherit;text-decoration:none">на ☕️ Юмани</a></button>
    <button><a href="https://www.tinkoff.ru/rm/seroshtanov.aleksey9/HgzXr74936" style="color:inherit;text-decoration:none">на ☕️Тинькофф</a></button>
    <button onclick="addInterface()">🆕Добавить интерфейс</button>
    <button onclick="generateConfig()">🆗Сгенерировать конфиг</button>
    <button onclick="saveConfig()">🆙Сохранить на роутер</button>
  </div>

  <div id="warnings"></div>
  <div id="interfacesContainer"></div>

  <div id="configDisplay" class="config-display" style="display:none;">
    <pre><code id="output" class="language-json"></code></pre>
  </div>

  <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/highlight.min.js"></script>
  <script>
    /* ======================= FRONTEND: sing-box only ======================= */
    let config = {}, interfaceCount = 0, isConfigModified = false;

    function addInterface() {
      interfaceCount++; isConfigModified = true;
      const container = document.createElement('div');
      container.className = 'interface-container'; container.id = `interface-${interfaceCount}`;

      const header = document.createElement('div'); header.className = 'interface-header';
      const delBtn = document.createElement('button'); delBtn.textContent = '🗑️';
      delBtn.title = 'Удалить интерфейс';
      delBtn.onclick = () => { container.remove(); isConfigModified = true; };
      const nameInput = document.createElement('input'); nameInput.type='text';
      nameInput.placeholder='Название интерфейса (например, Proxy0)';
      nameInput.value = `Proxy${interfaceCount - 1}`; nameInput.maxLength = 20;

      header.appendChild(delBtn); header.appendChild(nameInput);
      container.appendChild(header);

      const linksContainer = document.createElement('div'); linksContainer.className = 'links-container';
      container.appendChild(linksContainer);

      document.getElementById('interfacesContainer').appendChild(container);
      addLinkField(linksContainer);
    }

    function addLinkField(container) {
      const row = document.createElement('div'); row.className = 'link-field';
      const input = document.createElement('input'); input.type = 'text';
      input.placeholder = 'vless://...';
      row.appendChild(input); container.appendChild(row);
    }

    // helper: Proxy2 -> 2; без цифры -> fallbackIdx
    function pickIndexFromName(name, fallbackIdx) {
      const m = String(name || '').match(/(\d+)$/);
      return m ? parseInt(m[1], 10) : fallbackIdx;
    }

    // vless:// -> outbound sing-box
    function parseVlessForSingbox(link) {
      const m = link.match(/vless:\/\/([^@]+)@([^:]+):(\d+)(?:\/?\?([^#]*))?(?:#(.*))?/);
      if (!m) return null;
      const uuid = m[1], server = m[2], server_port = parseInt(m[3],10);
      const q = new URLSearchParams(m[4]||''); const tag = decodeURIComponent(m[5]||'').trim() || `vless-${server}-${server_port}`;
      const o = { type:"vless", tag, server, server_port, uuid, packet_encoding: q.get("pe")||"xudp" };
      const sec = q.get("security") || "none";
      if (sec === "tls" || sec === "reality") {
        o.tls = { enabled:true, server_name:q.get("sni")||server, insecure:false, utls:{ enabled:true, fingerprint:q.get("fp")||"chrome" } };
        if (sec === "reality") o.tls.reality = { enabled:true, public_key:q.get("pbk")||"", short_id:q.get("sid")||"" };
      }
      const flow = q.get("flow"); if (flow) o.flow = flow;
      return o;
    }

    function generateConfig() {
      // собираем конфиг sing-box из UI
      const cfg = {
        experimental: {
          cache_file: { enabled: true },
          clash_api: {
            external_controller: "192.168.1.1:9090",
            external_ui: "ui",
            access_control_allow_private_network: true
          }
        },
        log: { level: "debug", timestamp: true },
        inbounds: [],
        outbounds: [],
        route: { auto_detect_interface: false, rules: [], final: "direct" }
      };

      const usedTags = new Set(), usedPorts = new Set();
      const interfaces = document.querySelectorAll('.interface-container');

      interfaces.forEach((ic, idx) => {
        const rawName = ic.querySelector('.interface-header input[type="text"]')?.value?.trim() || '';
        const n = pickIndexFromName(rawName, idx);
        const tagInbound = `proxy${n}`.toLowerCase();
        let listen_port = 1081 + n; while (usedPorts.has(listen_port)) listen_port++; usedPorts.add(listen_port);

        // inbound
        cfg.inbounds.push({
          type: "mixed", tag: tagInbound, listen: "0.0.0.0",
          listen_port, sniff: true, sniff_override_destination: false
        });

        // 1-я валидная vless:// ссылка → outbound + правило
        const links = ic.querySelectorAll('.links-container input[type="text"]');
        for (const inp of links) {
          const raw = (inp.value||'').trim(); if (!raw || !raw.startsWith('vless://')) continue;
          const o = parseVlessForSingbox(raw); if (!o) continue;
          if (!usedTags.has(o.tag)) { cfg.outbounds.push(o); usedTags.add(o.tag); }
          cfg.route.rules.push({ inbound: [tagInbound], action: "route", outbound: o.tag });
          break;
        }
      });

      // системные outbounds и правило запрета udp/443
      cfg.outbounds.push({ type: "direct", tag: "direct" });
      cfg.outbounds.push({ type: "block",  tag: "block"  });
      cfg.route.rules.unshift({ network: "udp", port: 443, action: "route", outbound: "block" });

      config = cfg;

      const out = document.getElementById('output');
      out.textContent = JSON.stringify(config, null, 2);
      hljs.highlightElement(out);
      document.getElementById('configDisplay').style.display = 'block';
    }

    function saveConfig() {
      if (!config || !config.inbounds) { document.getElementById('warnings').innerHTML = "❌Нет конфигурации для сохранения"; return; }
      fetch('', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(config, null, 2)
      })
      .then(r => r.json())
      .then(d => alert(d.message || "Готово"))
      .catch(e => { console.error(e); alert("Ошибка при отправке конфига"); });
    }
  </script>
</body>
</html>
