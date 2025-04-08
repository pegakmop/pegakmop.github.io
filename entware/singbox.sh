#!/bin/sh
echo "начало обновления репозитория, установки и настройки sing box go"
# Установка необходимых пакетов
opkg update
opkg install sing-box-go iptables

echo "Запрос данных у пользователя"
read -p "Введите IP сервера: " SERVER_IP
read -p "Введите порт сервера: " SERVER_PORT
read -p "Введите ID сервера: (uuid)" SERVER_ID
read -p "Введите публичный ключ сервера: " PUBLIC_KEY
read -p "Введите серверное имя (сайт под который маскируемся): " SERVER_NAME
read -p "Введите short ID: " SHORT_ID

echo "Создание конфигурации для sing-box"
cat << EOF > /opt/etc/sing-box/config.json
{
  "experimental": {
    "cache_file": {
      "enabled": true
    },
    "clash_api": {
      "external_controller": "192.168.1.1:9090",
      "external_ui": "ui",
      "access_control_allow_private_network": true
    }
  },
  "log": {
    "level": "debug"
  },
  "inbounds": [
    {
      "type": "tun",
      "interface_name": "tun0",
      "domain_strategy": "ipv4_only",
      "address": "172.16.50.1/30",
      "auto_route": false,
      "strict_route": false,
      "sniff": true
    },
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "0.0.0.0",
      "listen_port": 1080
    }
  ],
  "outbounds": [
    {
      "type": "selector",
      "tag": "select",
      "outbounds": [
        "finland"
      ],
      "default": "finland",
      "interrupt_exist_connections": false
    },
    {
      "type": "vless",
      "tag": "finland",
      "server": "$SERVER_IP",
      "server_port": $SERVER_PORT,
      "uuid": "$SERVER_ID",
      "flow": "xtls-rprx-vision",
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
    "auto_detect_interface": false
  }
}
EOF

echo "Конфигурация для sing-box успешно создана."

echo "Создание скрипта для настройки фаервола"
cat << EOF > /opt/etc/ndm/netfilter.d/020-sing-box.sh
#!/opt/bin/sh

#echo "020-sing-box.sh: Скрипт запущен"

# Ждём 5 секунд, чтобы интерфейс tun+ успел появиться
#sleep 5

# Функция для проверки существования правила
rule_exists() {
    iptables-save | grep -q -- "\$1"
}

# Добавляем правило INPUT, если его ещё нет
if ! rule_exists "-A INPUT -i tun+ -j ACCEPT"; then
    /opt/sbin/iptables -A INPUT -i tun+ -j ACCEPT
    logger "020-sing-box.sh: Добавлено правило INPUT для tun+"
else
    logger "020-sing-box.sh: Правило INPUT для tun+ уже существует"
fi

# Добавляем правило FORWARD (входящий трафик), если его ещё нет
if ! rule_exists "-A FORWARD -i tun+ -j ACCEPT"; then
    /opt/sbin/iptables -A FORWARD -i tun+ -j ACCEPT
    logger "020-sing-box.sh: Добавлено правило FORWARD (вход) для tun+"
else
    logger "020-sing-box.sh: Правило FORWARD (вход) для tun+ уже существует"
fi

# Добавляем правило FORWARD (исходящий трафик), если его ещё нет
if ! rule_exists "-A FORWARD -o tun+ -j ACCEPT"; then
    /opt/sbin/iptables -A FORWARD -o tun+ -j ACCEPT
    logger "020-sing-box.sh: Добавлено правило FORWARD (выход) для tun+"
else
    logger "020-sing-box.sh: Правило FORWARD (выход) для tun+ уже существует"
fi
EOF

echo "Даем права на выполнение скрипта"
chmod +x /opt/etc/ndm/netfilter.d/020-sing-box.sh

echo "Запуск скрипта фаервола"
/opt/etc/ndm/netfilter.d/020-sing-box.sh

echo "Перезапуск службы sing-box"
/opt/etc/init.d/S99sing-box restart

echo "Проверка состояния службы"
/opt/etc/init.d/S99sing-box check

echo "Проверка iptables"
iptables-save | grep tun+

echo "Проверка через curl"
curl --interface tun0 ifconfig.me

echo "веб панель singbox доступна по адресу http://192.168.1.1:9090"
