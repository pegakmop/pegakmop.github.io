#!/bin/sh

# Проверка и установка компонента proxy + настройка Proxy0 для Keenetic

check_proxy_component=1   # Включаем проверку (можно отключить, если не нужно)

if [ "$check_proxy_component" = "1" ]; then
    success=0

    for i in 1 2 3; do
        output=$(ndmc -c "components list" 2>&1)
        if echo "$output" | grep -q "name: proxy" && echo "$output" | grep -q "installed:"; then
            success=1
            break
        fi
        sleep 5 # подождать 1 сек. между проверками (меньше для слабого MIPS не стоит)
    done

    if [ $success -eq 1 ]; then
        echo "✅ Компонент proxy установлен."
        echo "⏳ Настраиваю Proxy0..."

        echo "Удаляем старый Proxy0 (если был)"
        ndmc -c "no interface Proxy0" >/dev/null 2>&1

        echo "Создаём и настраиваем новый Proxy0"
        ndmc -c "interface Proxy0"
        ndmc -c "interface Proxy0 description mihomo-Proxy0-192.168.1.1:7890"
        ndmc -c "interface Proxy0 proxy protocol socks5"
        ndmc -c "interface Proxy0 proxy socks5-udp"
        ndmc -c "interface Proxy0 proxy upstream 192.168.1.1 7890"
        ndmc -c "interface Proxy0 up"
        ndmc -c "interface Proxy0 ip global 1"

        echo "Сохраняем конфигурацию"
        ndmc -c "system configuration save"

        echo "✅ Proxy0 успешно создан и настроен, если не было ошибок!"
    else
        echo "❌ Компонент proxy не установлен."
        echo "⚠️ Установка Proxy0 невозможна."
        echo "➡️ В веб-интерфейсе Keenetic: Параметры системы → Изменить набор компонентов → Клиент прокси → включите галочку и сохраните."
        exit 1
    fi
fi
