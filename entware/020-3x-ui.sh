#!/opt/bin/sh
# curl -o /opt/etc/ndm/netfilter.d/020-3x-ui.sh https://raw.githubusercontent.com/pegakmop/pegakmop.github.io/refs/heads/main/entware/020-3x-ui.sh
# chmod +x /opt/etc/ndm/netfilter.d/020-3x-ui.sh
# /opt/etc/ndm/netfilter.d/020-3x-ui.sh

# Получаем имя скрипта автоматически
SCRIPT_NAME=$(basename "$0")

# Проверка и установка iptables при первом запуске
if [ ! -f /opt/sbin/iptables ]; then
    logger "$SCRIPT_NAME: iptables not found, installing..."
    opkg update
    opkg install iptables
    if [ $? -eq 0 ]; then
        logger "$SCRIPT_NAME: iptables successfully installed"
    else
        logger "$SCRIPT_NAME: ERROR - failed to install iptables"
        exit 1
    fi
fi

# Ждём 5 секунд, чтобы интерфейсы tun+, t2s+ и opkgtun+ успели появиться
sleep 5

# Функция для проверки существования правила
rule_exists() {
    /opt/sbin/iptables-save | grep -q -- "$1"
}

# Добавляем правила для tun+
RULE="-A INPUT -i tun+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A INPUT -i tun+ -j ACCEPT
    logger "$SCRIPT_NAME: Added rule: $RULE"
fi

RULE="-A FORWARD -i tun+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A FORWARD -i tun+ -j ACCEPT
    logger "$SCRIPT_NAME: Added rule: $RULE"
fi

RULE="-A FORWARD -o tun+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A FORWARD -o tun+ -j ACCEPT
    logger "$SCRIPT_NAME: Added rule: $RULE"
fi

# Добавляем правила для t2s+
RULE="-A INPUT -i t2s+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A INPUT -i t2s+ -j ACCEPT
    logger "$SCRIPT_NAME: Added rule: $RULE"
fi

RULE="-A FORWARD -i t2s+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A FORWARD -i t2s+ -j ACCEPT
    logger "$SCRIPT_NAME: Added rule: $RULE"
fi

RULE="-A FORWARD -o t2s+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A FORWARD -o t2s+ -j ACCEPT
    logger "$SCRIPT_NAME: Added rule: $RULE"
fi

# Добавляем правила для opkgtun+
RULE="-A INPUT -i opkgtun+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A INPUT -i opkgtun+ -j ACCEPT
    logger "$SCRIPT_NAME: Added rule: $RULE"
fi

RULE="-A FORWARD -i opkgtun+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A FORWARD -i opkgtun+ -j ACCEPT
    logger "$SCRIPT_NAME: Added rule: $RULE"
fi

RULE="-A FORWARD -o opkgtun+ -j ACCEPT"
if ! rule_exists "$RULE"; then
    /opt/sbin/iptables -A FORWARD -o opkgtun+ -j ACCEPT
    logger "$SCRIPT_NAME: Added rule: $RULE"
fi

logger "$SCRIPT_NAME: Script completed successfully"
