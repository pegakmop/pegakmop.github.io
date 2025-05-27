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

INTERFACE="Proxy0"

if [ "$action" = "add" ]; then
    for net in $ROUTES; do
        ndmc -c "ip route $net $INTERFACE auto" >/dev/null 2>&1
    done
    ndmc -c "system configuration save" >/dev/null 2>&1
    echo "фикс установлен."
elif [ "$action" = "del" ]; then
    for net in $ROUTES; do
        ndmc -c "no ip route $net $INTERFACE" >/dev/null 2>&1
    done
    ndmc -c "system configuration save" >/dev/null 2>&1
    echo "фикс удален."
else
    echo "Неверное действие. Используйте add или del."
    exit 1
fi
