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
    logger "020-sing-box.sh: Added INPUT rule for tun+"
else
    logger "020-sing-box.sh: INPUT rule for tun+ already exists"
fi

# Добавляем правило FORWARD (входящий трафик), если его ещё нет
if ! rule_exists "-A FORWARD -i tun+ -j ACCEPT"; then
    /opt/sbin/iptables -A FORWARD -i tun+ -j ACCEPT
    logger "020-sing-box.sh: Added FORWARD input rule for tun+"
else
    logger "020-sing-box.sh: FORWARD input rule for tun+ already exists"
fi

# Добавляем правило FORWARD (исходящий трафик), если его ещё нет
if ! rule_exists "-A FORWARD -o tun+ -j ACCEPT"; then
    /opt/sbin/iptables -A FORWARD -o tun+ -j ACCEPT
    logger "020-sing-box.sh: Added FORWARD output rule for tun+"
else
    logger "020-sing-box.sh: FORWARD output rule for tun+ already exists"
fi
