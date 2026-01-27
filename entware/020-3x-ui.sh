#!/opt/bin/sh
# chmod +x /opt/etc/ndm/netfilter.d/020-3x-ui.sh
# /opt/etc/ndm/netfilter.d/020-3x-ui.sh
# Ждём 5 секунд, чтобы интерфейсы tun+, t2s+ и opkgtun+ успели появиться
sleep 5

# Функция для проверки существования правила
rule_exists() {
    iptables-save | grep -q -- "$1"
}

# Добавляем правила для tun+
RULE="-A INPUT -i tun+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A INPUT -i tun+ -j ACCEPT
    logger "020-x-ui.sh: Added rule: $RULE"
else
    :
fi

RULE="-A FORWARD -i tun+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A FORWARD -i tun+ -j ACCEPT
    logger "020-x-ui.sh: Added rule: $RULE"
else
    :
fi

RULE="-A FORWARD -o tun+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A FORWARD -o tun+ -j ACCEPT
    logger "020-x-ui.sh: Added rule: $RULE"
else
    :
fi

# Добавляем правила для t2s+
RULE="-A INPUT -i t2s+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A INPUT -i t2s+ -j ACCEPT
    logger "020-x-ui.sh: Added rule: $RULE"
else
    :
fi

RULE="-A FORWARD -i t2s+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A FORWARD -i t2s+ -j ACCEPT
    logger "020-x-ui.sh: Added rule: $RULE"
else
    :
fi

RULE="-A FORWARD -o t2s+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A FORWARD -o t2s+ -j ACCEPT
    logger "020-x-ui.sh: Added rule: $RULE"
else
    :
fi

# Добавляем правила для opkgtun+
RULE="-A INPUT -i opkgtun+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A INPUT -i opkgtun+ -j ACCEPT
    logger "020-x-ui.sh: Added rule: $RULE"
else
    :
fi

RULE="-A FORWARD -i opkgtun+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A FORWARD -i opkgtun+ -j ACCEPT
    logger "020-x-ui.sh: Added rule: $RULE"
else
    :
fi

RULE="-A FORWARD -o opkgtun+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A FORWARD -o opkgtun+ -j ACCEPT
    logger "020-x-ui.sh: Added rule: $RULE"
else
    :
fi
