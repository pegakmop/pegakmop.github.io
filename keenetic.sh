#!/bin/sh
# curl -fsSL https://www.pegakmop.site/keenetic.sh | sh

# === АНИМАЦИЯ ===
animation() {
    local pid=$1 message=$2 spin='|/-\\' i=0
    echo -n "[ ] $message..."
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r[%s] %s..." "${spin:$i:1}" "$message"
        usleep 100000
    done
    wait $pid
    if [ $? -eq 0 ]; then
        printf "\r[✔] %s\n" "$message"
    else
        printf "\r[✖] %s\n" "$message"
    fi
}

run_with_animation() {
    local msg="$1"
    shift
    ("$@") >/dev/null 2>&1 &
    animation $! "$msg"
}

run_with_animation "Запуск установки репозитория..."
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net" >/dev/null 2>&1
ndmc -c "system configuration save" >/dev/null 2>&1

run_with_animation "Обновление списка пакетов" opkg update
run_with_animation "Установка wget с поддержкой HTTPS" opkg install wget-ssl curl
run_with_animation "Удаление wget без SSL" opkg remove wget-nossl

# === Определение архитектуры ===
run_with_animation "Определение архитектуры системы..."
ARCH=$(opkg print-architecture | awk '/^arch/ && $2 !~ /_kn$/ && $2 ~ /-[0-9]+\.[0-9]+$/ {print $2; exit}')
if [ -z "$ARCH" ]; then echo "Не удалось определить архитектуру."; exit 1; fi

case "$ARCH" in
  aarch64-3.10) FEED_URL="https://www.pegakmop.site/release/keenetic/aarch64-k3.10" ;;
  mipsel-3.4)   FEED_URL="https://www.pegakmop.site/release/keenetic/mipselsf-k3.4" ;;
  mips-3.4)     FEED_URL="https://www.pegakmop.site/release/keenetic/mipssf-k3.4" ;;
  *) run_with_animation "Неподдерживаемая архитектура: $ARCH"; exit 1 ;;
esac

run_with_animation "Архитектура: $ARCH"
#echo "Выбранный репозиторий: $FEED_URL"

FEED_CONF="/opt/etc/opkg/neofit.conf"
FEED_LINE="src/gz pegakmop $FEED_URL"

[ ! -d "/opt/etc/opkg" ] && mkdir -p /opt/etc/opkg

if ! grep -q "$FEED_URL" "$FEED_CONF" 2>/dev/null; then
  run_with_animation "$FEED_LINE" >> "$FEED_CONF"
else
  echo "[✔] Репозиторий уже добавлен в $FEED_CONF..."
fi

run_with_animation "Обновление нового списка пакетов..." opkg update

# Optional cleanup
SCRIPT="$0"
if [ -f "$SCRIPT" ]; then
  run_with_animation "Удаляем установочный скрипт с устройства..."
  rm "$SCRIPT"
fi

run_with_animation "Установка репозитория успешно завершена."
