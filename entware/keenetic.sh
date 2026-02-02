#!/bin/sh
rm -rf /opt/etc/opkg/customfeeds.conf
rm -rf /opt/etc/opkg/neofit.conf
rm -rf /opt/var/opkg-lists/pegakmop
rm -rf /opt/var/opkg-lists/ground-zerro
echo "Обновление списка пакетов..."
opkg update
echo "Установка curl и wget-ssl..."
opkg install curl wget-ssl
opkg remove wget-nossl

echo "Определение архитектуры роутера кинетика..."
ARCH=$(opkg print-architecture | awk '
  /^arch/ && $2 !~ /_kn$/ && $2 ~ /-[0-9]+\.[0-9]+$/ {
    print $2; exit
  }'
)

if [ -z "$ARCH" ]; then
  echo "Ошибка определения архитектуры!"
  exit 1
fi

case "$ARCH" in
  aarch64-3.10)
    FEED_URL="https://www.pegakmop.site/release/keenetic/aarch64-k3.10"
    ;;
  mipsel-3.4)
    FEED_URL="https://www.pegakmop.site/release/keenetic/mipselsf-k3.4"
    ;;
  mips-3.4)
    FEED_URL="https://www.pegakmop.site/release/keenetic/mipssf-k3.4"
    ;;
  *)
    echo "Не поддерживаемая архитектура: $ARCH"
    exit 1
    ;;
esac

echo "Определена архитектура: $ARCH"
echo "Устанавливаю репозиторий: $FEED_URL"

FEED_CONF="/opt/etc/opkg/neofit.conf"
FEED_LINE="src/gz pegakmop $FEED_URL"

# Ensure the opkg directory exists
if [ ! -d "/opt/etc/opkg" ]; then
  echo "Создаем /opt/etc/opkg директорию..."
  mkdir -p /opt/etc/opkg
fi

# Check for existing feed entry
if grep -q "$FEED_URL" "$FEED_CONF" 2>/dev/null; then
  echo "Репозиторий установлен: $FEED_CONF. пропускаем установку."
else
  echo "Добавляем репозиторий $FEED_CONF..."
  echo "$FEED_LINE" >> "$FEED_CONF"
fi

echo "Обновляем все списки пакетов репозиториев..."
opkg update

# Optional cleanup
SCRIPT="$0"
if [ -f "$SCRIPT" ]; then
  echo "Удаляем установочный скрипт с устройства..."
  rm "$SCRIPT"
fi

echo "Установка репозитория успешно завершена."
