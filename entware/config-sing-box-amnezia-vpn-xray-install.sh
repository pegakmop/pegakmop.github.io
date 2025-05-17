#!/bin/sh
chmod +x "$0"
# Путь к исходному файлу amnezia_for_xray.json
INPUT_FILE="/opt/root/amnezia_for_xray.json"

# Проверка наличия файла
if [ ! -f "$INPUT_FILE" ]; then
  echo "ОШИБКА:  $INPUT_FILE файл не найден. Прекращаю выполнение установки и настройки sing box на вашем устройстве. в приложении Amnezia VPN выберите вкладку поделиться протокол xray и оригинальный формат xray и сохраните конфигурационный файл на роутере: $INPUT_FILE и после запустите скрипт "$0""
  exit 1
fi

# Путь к выходному файлу sing box с настройкой config.json 
#OUTPUT_FILE="/opt/etc/sing-box/config.json"

#для тестов использовал
OUTPUT_FILE="/opt/root/config.json"

echo "обновляю источники пакетов..."
opkg update

echo "обновляю установленные пакеты..."
opkg upgrade

echo "устанавливаю sing-box на ваше устройство, если он еще не установлен..."
opkg install sing-box-go

sleep 1


# Извлекаем значения для "vnext" из исходного файла
SERVER_ADDRESS=$(jq -r '.outbounds[0].settings.vnext[0].address' "$INPUT_FILE")
SERVER_PORT=$(jq -r '.outbounds[0].settings.vnext[0].port' "$INPUT_FILE")
UUID=$(jq -r '.outbounds[0].settings.vnext[0].users[0].id' "$INPUT_FILE")
FLOW=$(jq -r '.outbounds[0].settings.vnext[0].users[0].flow' "$INPUT_FILE")
SERVER_NAME=$(jq -r '.outbounds[0].streamSettings.realitySettings.serverName' "$INPUT_FILE")
PUBLIC_KEY=$(jq -r '.outbounds[0].streamSettings.realitySettings.publicKey' "$INPUT_FILE")
SHORT_ID=$(jq -r '.outbounds[0].streamSettings.realitySettings.shortId' "$INPUT_FILE")

rm -f "$OUTPUT_FILE"
echo "дефолтная конфигурация успешно удалена: $OUTPUT_FILE"
sleep 1

# Создаем новый config.json
cat <<EOF > "$OUTPUT_FILE"
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
      "address": "172.16.250.1/30",
      "auto_route": true,
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
        "$SERVER_ADDRESS"
      ],
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
      {
        "inbound": ["tun"],
        "outbound": "select"
      }
    ]
  }
}
EOF

echo "Конфигурация успешно создана и настроена: $OUTPUT_FILE"
sleep 1
echo "перезагрузка роутера произойдет через 60 секунд для активации конфигурации и проверки настройки sing-box, после перезагрузки вам будет доступен веб-интерфейс по адресу http://192.168.1.1:9090"
#sleep 60
#reboot