#!/bin/sh
#запуск скрипта
#curl -o /opt/tmp/sing-box-fix.sh https://pegakmop.github.io/entware/voice.sh && chmod +x /opt/tmp/sing-box-fix.sh && /opt/tmp/sing-box-fix.sh

read -p "Введите действие (add/del): " action

ROUTES="
138.128.136.0/21
162.158.0.0/15
172.64.0.0/13
34.0.0.0/15
34.2.0.0/16
34.3.0.0/23
34.3.2.0/24
35.192.0.0/12
35.208.0.0/12
35.224.0.0/12
35.240.0.0/13
5.200.14.128/25
66.22.192.0/18
"

# Извлекаем имена интерфейсов ProxyN и WireguardN из ndmc
INTERFACES=$(ndmc -c "show interface" | grep 'Interface, name =' | grep -Eo '"(Proxy|Wireguard)[0-9]+"' | tr -d '"')

if [ -z "$INTERFACES" ]; then
    echo "❌ Подходящие интерфейсы не найдены."
    exit 1
fi

# Вывод списка с номерами
echo "Выберите интерфейс для маршрутов:"
i=1
DEFAULT_NUM=""
for iface in $INTERFACES; do
    echo "  $i) $iface"
    eval iface_$i="$iface"
    [ "$iface" = "Proxy0" ] && DEFAULT_NUM=$i
    [ "$iface" = "Wireguard0" ] && [ -z "$DEFAULT_NUM" ] && DEFAULT_NUM=$i
    i=$((i + 1))
done

read -p "Введите номер интерфейса [по умолчанию Proxy0 → Wireguard0]: " num

if [ -z "$num" ]; then
    if [ -z "$DEFAULT_NUM" ]; then
        echo "❌ Нет Proxy0 или Wireguard0 для выбора по умолчанию."
        exit 1
    fi
    num=$DEFAULT_NUM
fi

eval INTERFACE=\$iface_$num

if [ -z "$INTERFACE" ]; then
    echo "❌ Неверный выбор. Скрипт завершён."
    exit 1
fi

# Основная логика
if [ "$action" = "add" ]; then
    for net in $ROUTES; do
        ndmc -c "ip route $net $INTERFACE auto" >/dev/null 2>&1
    done
    ndmc -c "system configuration save" >/dev/null 2>&1
    echo "✅ Фикс установлен на интерфейс $INTERFACE."
elif [ "$action" = "del" ]; then
    for net in $ROUTES; do
        ndmc -c "no ip route $net $INTERFACE" >/dev/null 2>&1
    done
    ndmc -c "system configuration save" >/dev/null 2>&1
    echo "🗑️ Фикс удалён с интерфейса $INTERFACE."
else
    echo "❌ Неверное действие. Используйте add или del."
    exit 1
fi

rm "$0"

echo "установка или удаление завершены"
