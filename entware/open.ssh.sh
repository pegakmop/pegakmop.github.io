#!/bin/sh
# Установочный скрипт для SSH уведомлений в Telegram о входе пользователя в ssh от @pegakmop

SCRIPT_PATH="/opt/bin/open.ssh.sh"
PROFILE_PATH="/opt/root/.profile"
STARTUP_LINE="/opt/bin/open.ssh.sh &"

echo "=========================================="
echo "  Установка SSH уведомлений в Telegram о входе в ssh"
echo
echo "create by @pegakmop"
echo
"=========================================="
echo ""

# Запрашиваем User ID
echo -n "Введите ваш Telegram User ID: "
read USERID

# Проверка на пустое значение
if [ -z "$USERID" ]; then
    echo "Ошибка: User ID не может быть пустым!"
    exit 1
fi

# Запрашиваем токен бота
echo -n "Введите токен Telegram бота: "
read KEY

# Проверка на пустое значение
if [ -z "$KEY" ]; then
    echo "Ошибка: Токен бота не может быть пустым!"
    exit 1
fi

echo ""
echo "Установка с параметрами:"
echo "  User ID: $USERID"
echo "  Bot Token: ${KEY:0:10}...${KEY: -10}"
echo ""

# Создаем скрипт open.ssh.sh
cat > "$SCRIPT_PATH" << EOF
#!/bin/sh
# SSH notifications to Telegram
USERID="$USERID"
KEY="$KEY"
TIMEOUT="10"
URL="https://api.telegram.org/bot\$KEY/sendMessage"
DATE_EXEC="\$(date "+%d %B %Y %H:%M")"

if [ -n "\$SSH_CLIENT" ]; then
    IP=\$(echo \$SSH_CLIENT | awk '{print \$1}')
    PORT=\$(echo \$SSH_CLIENT | awk '{print \$3}')
    HOSTNAME=\$(hostname)
    IPADDR=\$(ip addr show br0 | grep 'inet ' | awk '{print \$2}' | cut -d'/' -f1)
    
    TEXT="\$DATE_EXEC
Вход пользователя \${USER} по ssh на \$HOSTNAME (\$IPADDR)
С \$IP через порт \$PORT"
    
    /opt/bin/curl -s --max-time \$TIMEOUT -d \\
    "chat_id=\$USERID&disable_web_page_preview=1&text=\$TEXT" \\
    \$URL > /dev/null
fi
EOF

# Даем права на выполнение
chmod +x "$SCRIPT_PATH"
echo "✓ Скрипт создан: $SCRIPT_PATH"

# Проверяем, не добавлена ли уже строка в profile
if grep -q "$STARTUP_LINE" "$PROFILE_PATH" 2>/dev/null; then
    echo "⚠ Строка уже присутствует в $PROFILE_PATH"
else
    # Добавляем строку в конец profile
    echo "" >> "$PROFILE_PATH"
    echo "# SSH Telegram notifications" >> "$PROFILE_PATH"
    echo "$STARTUP_LINE" >> "$PROFILE_PATH"
    echo "✓ Добавлено в $PROFILE_PATH"
fi

echo ""
echo "=========================================="
echo "  Установка завершена успешно!"
echo "=========================================="
echo "Переподключитесь по SSH для проверки."
echo ""
echo "Для удаления используйте:"
echo "  sed -i '/\\/opt\\/bin\\/open.ssh.sh/d' $PROFILE_PATH"
echo "  rm $SCRIPT_PATH"
