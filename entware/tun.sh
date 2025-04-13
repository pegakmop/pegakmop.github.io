#!/opt/bin/sh

# Ждём 5 секунд, чтобы интерфейс tun0 успел появиться
sleep 5

# Функция для проверки существования правила
rule_exists() {
    iptables-save | grep -q -- "$1"
}

# INPUT для tun+
if ! rule_exists "-A INPUT -i tun+ -j ACCEPT"; then
    /opt/sbin/iptables -A INPUT -i tun+ -j ACCEPT
    logger "tun.sh: Added INPUT rule for tun+"
else
    logger "tun.sh: INPUT rule for tun+ already exists"
fi

# FORWARD входящий для tun+
if ! rule_exists "-A FORWARD -i tun+ -j ACCEPT"; then
    /opt/sbin/iptables -A FORWARD -i tun+ -j ACCEPT
    logger "tun.sh: Added FORWARD input rule for tun+"
else
    logger "tun.sh: FORWARD input rule for tun+ already exists"
fi

# FORWARD исходящий для tun+
if ! rule_exists "-A FORWARD -o tun+ -j ACCEPT"; then
    /opt/sbin/iptables -A FORWARD -o tun+ -j ACCEPT
    logger "tun.sh: Added FORWARD output rule for tun+"
else
    logger "tun.sh: FORWARD output rule for tun+ already exists"
fi

# MASQUERADE для tun0
if ! rule_exists "-A POSTROUTING -o tun0 -j MASQUERADE"; then
    /opt/sbin/iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
    logger "tun.sh: Added MASQUERADE for tun0"
else
    logger "tun.sh: MASQUERADE for tun0 already exists"
fi

# test nat tun0
