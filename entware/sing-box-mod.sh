#!/bin/sh

# Логгер
log() {
  echo "$1"
  logger "$1"
}

apply_routing_settings() {
	cat << 'EOF' > "$RULES_SCRIPT_PATH"
#!/opt/bin/sh

if ps | grep -v grep | grep "020-sing-box.sh" | grep -qv "$$"; then
    exit 0
fi

rule_exists() {
    iptables-save | grep -q -- "$1"
}

if ! rule_exists "-A INPUT -i tun+ -j ACCEPT"; then
    /opt/sbin/iptables -A INPUT -i tun+ -j ACCEPT
fi

if ! rule_exists "-A FORWARD -i tun+ -j ACCEPT"; then
    /opt/sbin/iptables -A FORWARD -i tun+ -j ACCEPT
fi

if ! rule_exists "-A FORWARD -o tun+ -j ACCEPT"; then
    /opt/sbin/iptables -A FORWARD -o tun+ -j ACCEPT
fi
EOF
	chmod +x "$RULES_SCRIPT_PATH"
    
    log "ℹ Применение правил маршрутизации..."
	$RULES_SCRIPT_PATH
	sleep 3
	
	if iptables-save | grep -q 'tun\+'; then
		log "✅ Правила маршрутизации добавлены."
	else
		log "❌ Не удалось добавить правила маршрутизации."
		exit 1
	fi

    log "ℹ Проверка конфига sing-box..."
	if sing-box -c "$OUTPUT_FILE" check; then
		log "✅ Конфигурация в порядке."
	else
		log "❌ Конфигурация содержит ошибки."
		exit 1
	fi
    sleep 2
    /opt/etc/init.d/S99sing-box stop >/dev/null 2>&1

    log "ℹ Настройка Proxy0..."
	# удаляем Proxy0, если есть
    ndmc -c "no interface Proxy0" >/dev/null 2>&1
	ndmc -c 'system configuration save' >/dev/null 2>&1
	# создаем Proxy0
    ndmc -c "interface Proxy0"
    ndmc -c "interface Proxy0 description @pegakmop-$IP_ADDRESS:1080"
    ndmc -c "interface Proxy0 proxy protocol socks5"
    ndmc -c "interface Proxy0 proxy socks5-udp"
    ndmc -c "interface Proxy0 proxy upstream $IP_ADDRESS 1080"
    ndmc -c "interface Proxy0 up"
    ndmc -c "interface Proxy0 ip global 1"
	ndmc -c "system configuration save"
	sleep 5
	
    log "ℹ Проверка состояния Proxy0..."
	# Получаем вывод
	output=$(ndmc -c "show interface Proxy0" | awk '/summary:/,0' | awk '/layer:/,0' | sed -n '/layer:/,$p' | sed '1d' | sed 's/^[[:space:]]*//')
	# Извлекаем значения параметров
	conf=$(echo "$output" | awk '/^conf:/ {print $2}')
	link=$(echo "$output" | awk '/^link:/ {print $2}')
	ipv4=$(echo "$output" | awk '/^ipv4:/ {print $2}')
	ctrl=$(echo "$output" | awk '/^ctrl:/ {print $2}')
	# Проверяем состояния
	if [[ "$conf" == "running" && "$link" == "running" && "$ipv4" == "running" && "$ctrl" == "running" ]]; then
		log "✅ Интерфейс Proxy0 работает."
	else
		log "❌ Сбой настройки интерфейса Proxy0."
		exit 1
	fi

    while true; do
        echo "Выберите кто будет управлять sing-box, что бы установить ответьте числом:"
        echo "1) magitrickle"
        echo "2) HydraRoute Neo"
        echo "3) HydraRoute Classic"
        echo "4) Отменить установку"

        read -p "Введите номер (1-4): " choice

        case "$choice" in
            1)
                echo "ℹ Установка magitrickle..."
                opkg install magitrickle
                break
                ;;
            2)
                echo "ℹ Установка HydraRoute Neo..."
                opkg install hrneo
				neo restart >/dev/null 2>&1
				sleep 3
				ndmc -c 'ip policy HydraRoute permit global Proxy0' >/dev/null 2>&1
				ndmc -c 'system configuration save' >/dev/null 2>&1
                break
                ;;
            3)
                echo "ℹ Установка HydraRoute Classic..."
                opkg install hydraroute
				hr restart >/dev/null 2>&1
				sleep 3
				ndmc -c 'ip policy HydraRoute1st permit global Proxy0' >/dev/null 2>&1
				ndmc -c 'system configuration save' >/dev/null 2>&1
                break
                ;;
            4)
                echo "🚫 Установка отменена, сами устанавливать будете магитрикл или гидру."
                break
                ;;
            *)
                echo "❌ Неверный выбор. Пожалуйста, введите число от 1 до 4."
                sleep 1
                ;;
        esac
    done
    
    sb restart >/dev/null 2>&1
    neo restart >/dev/null 2>&1
    #sing-box run -c "$OUTPUT_FILE"
	
	log "✅ Установка завершена."
	log "ℹ Веб-интерфейс Sing-Box: http://$IP_ADDRESS:9090"
	#Удаление скрипта (пока отключено)
	#rm -f "$0"
	exit 0
}

log "=== Запуск скрипта установки Sing-Box на ваше устройство ==="
log "ℹ Обновление списка пакетов..."
opkg update
log "ℹ Установка wget с поддержкой HTTPS и curl..."
opkg install wget-ssl curl && opkg remove wget-nossl

# Настройка репозиториев
log "ℹ Определение архитектуры..."
if [ ! -d "/opt/etc/opkg" ]; then
  mkdir -p /opt/etc/opkg
fi

ARCH=$(opkg print-architecture | awk '{print $3, $2}' | sort -n | tail -n1 | awk '{print $2}')
[ -z "$ARCH" ] && { log "❌ Не удалось определить архитектуру"; exit 1; }

log "✅ Архитектура: $ARCH"
log "ℹ Добавление репозиториев..."

if echo "src/gz magitrickle http://bin.magitrickle.dev/packages/entware/$ARCH" > /opt/etc/opkg/magitrickle.conf; then
    log "✅ Репозиторий MagiTrickle добавлен."
else
    log "❌ Не удалось добавить репозиторий MagiTrickle."
fi

ARCH=$(opkg print-architecture | awk '/^arch/ && $2 !~ /_kn$/ && $2 ~ /-[0-9]+\.[0-9]+$/ {print $2; exit}')
case "$ARCH" in
  aarch64-3.10) FEED_URL="https://ground-zerro.github.io/release/keenetic/aarch64-k3.10" ;;
  mipsel-3.4) FEED_URL="https://ground-zerro.github.io/release/keenetic/mipselsf-k3.4" ;;
  mips-3.4) FEED_URL="https://ground-zerro.github.io/release/keenetic/mipssf-k3.4" ;;
  *) log "❌ Неподдерживаемая архитектура"; exit 1 ;;
esac

FEED_CONF="/opt/etc/opkg/customfeeds.conf"
FEED_LINE="src/gz HydraRoute $FEED_URL"

if ! grep -qF "$FEED_LINE" "$FEED_CONF" 2>/dev/null; then
  echo "$FEED_LINE" >> "$FEED_CONF"
  log "✅ Репозиторий HyrdaRoute добавлен."
else
  log "✅ Репозиторий HyrdaRoute был добавлен ранее."
fi

log "ℹ Обновление списка пакетов из добавленных репозиториев..."
opkg update

log "ℹ Установка необходимых пакетов..."
opkg install ca-bundle iptables jq sing-box-go
INPUT_FILE="/opt/root/amnezia_for_xray.json"
OUTPUT_FILE="/opt/etc/sing-box/config.json"
CONFIG_PATH="/opt/etc/sing-box/config.json"
RULES_SCRIPT_PATH="/opt/etc/ndm/netfilter.d/020-sing-box.sh"
IP_ADDRESS=$(ip addr show br0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

ln -sf /opt/etc/init.d/S99sing-box /opt/bin/sb
ln -sf /opt/etc/init.d/S99hydraroute /opt/bin/hr
ln -sf /opt/etc/init.d/S99magitrickle /opt/bin/mt
echo ""
log "⚠️ Любое копирование, изменение, публикация или распространение данного скрипта в любых других ресурсах без письменного разрешения автора @pegakmop (t.me/pegakmop) строго запрещено, будут страйки на каналы, жалобы и т.д, использование только с данного репозитория, приятной настройки и использования sing-box-go без заморочек с автонастройкой в один клик, скрипт написан для роутеров keenetic, ориентировался по более старой и доброй архитектуре mips, думаю на других проблем не должно возникнуть, отдельно касаясь ютуберов, я против обозреванич пока не будет в публичном доступе, на данный момент это альфа тест, как будет публичный надпись исчезнет со скрипта"
sleep 5
echo ""
echo "⚠️ По всем вопросам скрипта установщика пишем: https://t.me/pegakmop или в чате по ссылке: https://t.me/vpnconfiguration/62 так же пишите если вам нужен впн"
echo ""

# === Генерация основной конфигурации ===
log "ℹ Генерация нового конфига..."
if [ ! -f "$INPUT_FILE" ]; then
  log "❌ Файл конфигурации $INPUT_FILE не найден. Приготовьте ключ vless:// или ss:// для ввода..."
  #начало конфига
  echo "Введите ss:// или vless:// ссылку:"
  read LINK
  if [ -z "$LINK" ]; then
    echo "❌ Ссылка не введена, отмена установки."
      exit 1
  fi

  # Функция для URL-декодирования
  urldecode() {
    echo "$1" | sed 's/+/ /g;s/%/\\x/g' | xargs -0 printf '%b'
  }

  # Определяем тип ссылки
  case "$LINK" in
  ss://*)
    # Убираем префикс
    without_prefix="${LINK#ss://}"

    # Разделяем base64/метод:пароль и host:port
    part_before_at="${without_prefix%@*}"
    after_at="${without_prefix#*@}"

    # Декодируем URL-encoding
    part_before_at_decoded=$(printf '%b' "${part_before_at//%/\\x}")

    # Проверка, base64 это или метод:пароль
    if echo "$part_before_at_decoded" | grep -Eq '^[A-Za-z0-9+/=]+$'; then
      decoded=$(echo -n "$part_before_at_decoded" | base64 -d 2>/dev/null)
      if [ $? -ne 0 ]; then
        echo "Ошибка декодирования base64"
        exit 1
      fi
      method="${decoded%%:*}"
      password="${decoded#*:}"
    else
      method="${part_before_at_decoded%%:*}"
      password="${part_before_at_decoded#*:}"
    fi

    server_port="${after_at%%#*}"
    server="${server_port%:*}"
    port="${server_port##*:}"

    # Формируем конфиг для ss
    cat > "$CONFIG_PATH" <<EOF
{
  "experimental": {
    "cache_file": { "enabled": false },
    "clash_api": {
      "external_controller": "$IP_ADDRESS:9090",
      "external_ui": "ui",
      "access_control_allow_private_network": true
    }
  },
  "log": { "level": "debug" },
  "inbounds": [
    {
      "type": "tun",
      "interface_name": "tun0",
      "domain_strategy": "ipv4_only",
      "address": "172.16.250.1/30",
      "auto_route": false,
      "strict_route": false,
      "sniff": true
    },
    {
      "type": "socks",
      "tag": "socks",
      "listen": "0.0.0.0",
      "listen_port": 1080
    }
  ],
  "outbounds": [
    {
      "type": "shadowsocks",
      "tag": "proxy",
      "server": "$server",
      "server_port": $port,
      "method": "$method",
      "password": "$password"
    }
  ],
  "route": {
    "auto_detect_interface": false,
    "rules": [
      { "inbound": ["tun"], "outbound": "select" }
    ]
  }
}
EOF
    ;;

  vless://*)
    LINK_NO_PREFIX="${LINK#vless://}"

    UUID=$(echo "$LINK_NO_PREFIX" | cut -d '@' -f 1)
    REST="${LINK_NO_PREFIX#*@}"

    SERVER_ADDRESS=$(echo "$REST" | cut -d '?' -f 1 | cut -d ':' -f 1)
    SERVER_PORT=$(echo "$REST" | cut -d '?' -f 1 | cut -d ':' -f 2)

    QUERY=$(echo "$REST" | grep -oP '\?\K[^#]*')
    NAME=$(echo "$REST" | grep -oP '#\K.*')
    NAME=$(urldecode "$NAME")

    get_param() {
      echo "$QUERY" | tr '&' '\n' | grep -m1 "^$1=" | cut -d '=' -f 2
    }

    SECURITY=$(get_param "security")
    TYPE=$(get_param "type")
    SNI=$(get_param "sni")
    FP=$(get_param "fp")
    PBK=$(get_param "pbk")
    SID=$(get_param "sid")
    FLOW=$(get_param "flow")

    [ -z "$FP" ] && FP="chrome"
    [ -z "$SECURITY" ] && SECURITY="none"
    [ -z "$TYPE" ] && TYPE="tcp"

    cat > "$CONFIG_PATH" <<EOF
{
  "experimental": {
    "cache_file": { "enabled": true },
    "clash_api": {
      "external_controller": "$IP_ADDRESS:9090",
      "external_ui": "ui",
      "access_control_allow_private_network": true
    }
  },
  "log": { "level": "debug" },
  "inbounds": [
    {
      "type": "tun",
      "interface_name": "tun0",
      "domain_strategy": "ipv4_only",
      "address": "172.16.250.1/30",
      "auto_route": true,
      "strict_route": false,
      "sniff": true
    },
    {
      "type": "socks",
      "tag": "socks",
      "listen": "0.0.0.0",
      "listen_port": 1080
    }
  ],
  "outbounds": [
    {
      "type": "selector",
      "tag": "select",
      "outbounds": ["$SERVER_ADDRESS"],
      "default": "$SERVER_ADDRESS",
      "interrupt_exist_connections": false
    },
    {
      "type": "vless",
      "tag": "$SERVER_ADDRESS",
      "server": "$SERVER_ADDRESS",
      "server_port": $SERVER_PORT,
      "uuid": "$UUID",$(
        [ -n "$FLOW" ] && echo "
      \"flow\": \"$FLOW\","
      )
      "tls": {
        "enabled": true,
        "server_name": "$SNI",
        "utls": {
          "enabled": true,
          "fingerprint": "$FP"
        },
        "reality": {
          "enabled": true,
          "public_key": "$PBK",
          "short_id": "$SID"
        }
      }
    }
  ],
  "route": {
    "auto_detect_interface": false,
    "rules": [
      { "inbound": ["tun"], "outbound": "select" }
    ]
  }
}
EOF
    ;;

  *)
    echo "❌ Поддерживаются только ссылки ss:// и vless://"
    exit 1
    ;;
esac

apply_routing_settings
fi

log "ℹ Извлечение параметров из Amnezia-конфига..."
SERVER_ADDRESS=$(jq -r '.outbounds[0].settings.vnext[0].address' "$INPUT_FILE")
SERVER_PORT=$(jq -r '.outbounds[0].settings.vnext[0].port' "$INPUT_FILE")
UUID=$(jq -r '.outbounds[0].settings.vnext[0].users[0].id' "$INPUT_FILE")
FLOW=$(jq -r '.outbounds[0].settings.vnext[0].users[0].flow' "$INPUT_FILE")
SERVER_NAME=$(jq -r '.outbounds[0].streamSettings.realitySettings.serverName' "$INPUT_FILE")
PUBLIC_KEY=$(jq -r '.outbounds[0].streamSettings.realitySettings.publicKey' "$INPUT_FILE")
SHORT_ID=$(jq -r '.outbounds[0].streamSettings.realitySettings.shortId' "$INPUT_FILE")

cat <<EOF > "$OUTPUT_FILE"
{
  "experimental": {
    "cache_file": { "enabled": true },
    "clash_api": {
      "external_controller": "$IP_ADDRESS:9090",
      "external_ui": "ui",
      "access_control_allow_private_network": true
    }
  },
  "log": { "level": "debug" },
  "inbounds": [
    {
      "type": "tun",
      "interface_name": "tun0",
      "domain_strategy": "ipv4_only",
      "address": "172.16.250.1/30",
      "auto_route": true,
      "strict_route": false,
      "sniff": true
    },
    {
      "type": "socks",
      "tag": "socks",
      "listen": "0.0.0.0",
      "listen_port": 1080
    }
  ],
  "outbounds": [
    {
      "type": "selector",
      "tag": "select",
      "outbounds": ["$SERVER_ADDRESS"],
      "default": "$SERVER_ADDRESS",
      "interrupt_exist_connections": false
    },
    {
      "type": "vless",
      "tag": "$SERVER_ADDRESS",
      "server": "$SERVER_ADDRESS",
      "server_port": $SERVER_PORT,
      "uuid": "$UUID",
      "flow": "$FLOW",
      "tls": {
        "enabled": true,
        "server_name": "$SERVER_NAME",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
        "reality": {
          "enabled": true,
          "public_key": "$PUBLIC_KEY",
          "short_id": "$SHORT_ID"
        }
      }
    }
  ],
  "route": {
    "auto_detect_interface": false,
    "rules": [
      { "inbound": ["tun"], "outbound": "select" }
    ]
  }
}
EOF

apply_routing_settings
