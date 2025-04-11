#!/opt/bin/sh

# Ждём 5 секунд, чтобы интерфейс tun+ успел появиться
sleep 5

# Функция для проверки существования правила
rule_exists() {
    iptables-save | grep -q -- "$1"
}

# Добавляем правило INPUT, если его ещё нет
if ! rule_exists "-A INPUT -i tun+ -j ACCEPT"; then
    /opt/sbin/iptables -A INPUT -i tun+ -j ACCEPT
    logger "tun.sh: Added INPUT rule for tun+"
else
    logger "tun.sh: INPUT rule for tun+ already exists"
fi

# Добавляем правило FORWARD (входящий трафик), если его ещё нет
if ! rule_exists "-A FORWARD -i tun+ -j ACCEPT"; then
    /opt/sbin/iptables -A FORWARD -i tun+ -j ACCEPT
    logger "tun.sh: Added FORWARD input rule for tun+"
else
    logger "tun.sh: FORWARD input rule for tun+ already exists"
fi

# Добавляем правило FORWARD (исходящий трафик), если его ещё нет
if ! rule_exists "-A FORWARD -o tun+ -j ACCEPT"; then
    /opt/sbin/iptables -A FORWARD -o tun+ -j ACCEPT
    logger "tun.sh: Added FORWARD output rule for tun+"
else
    logger "tun.sh: FORWARD output rule for tun+ already exists"
fi
