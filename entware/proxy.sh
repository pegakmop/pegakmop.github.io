#!/bin/sh
#
# Скрипт проверки установки компонента proxy и настройки Proxy0 на Keenetic

check_proxy_component=1   # 1 = проверка включена, 0 = проверка выключена

if [ "$check_proxy_component" = "1" ]; then
    # Проверяем установлен ли компонент proxy
    if ndmc -c "components list" | grep -A15 "name: proxy" | grep "installed:"; then
        echo "✅ Компонент клиент прокси установлен"
        echo "⏳ Устанавливаю Proxy0..."

        # Удаляем старый Proxy0 (если есть)
        ndmc -c "no interface Proxy0" >/dev/null 2>&1

        # Создаём новый Proxy0 с настройкой
        ndmc -c "interface Proxy0"
        ndmc -c "interface Proxy0 description Proxy0-192.168.1.1:1080"
        ndmc -c "interface Proxy0 proxy protocol socks5"
        ndmc -c "interface Proxy0 proxy socks5-udp"
        ndmc -c "interface Proxy0 proxy upstream 192.168.1.1 1080"
        ndmc -c "interface Proxy0 up"
        ndmc -c "interface Proxy0 ip global 1"

        # Сохраняем конфигурацию
        ndmc -c "system configuration save"

        echo "✅ Proxy0 успешно создан и сохранён!"
    else
        echo "❌ Компонент КЛИЕНТ ПРОКСИ не установлен!"
        echo "➡️ В веб-интерфейсе Keenetic:"
        echo "Параметры системы → Изменить набор компонентов → Клиент прокси → включите галочку и сохраните."
        echo "Роутер перезагрузится после сохранения для установки компонента клиент прокси"
        exit 1
    fi
else
    # Если проверка отключена — просто создаём Proxy0 без проверки компонента
    echo "⏳ Устанавливаю Proxy0 (без проверки компонента proxy)..."

    ndmc -c "no interface Proxy0" >/dev/null 2>&1
    ndmc -c "interface Proxy0"
    ndmc -c "interface Proxy0 description Proxy0-192.168.1.1:1080"
    ndmc -c "interface Proxy0 proxy protocol socks5"
    ndmc -c "interface Proxy0 proxy socks5-udp"
    ndmc -c "interface Proxy0 proxy upstream 192.168.1.1 1080"
    ndmc -c "interface Proxy0 up"
    ndmc -c "interface Proxy0 ip global 1"
    ndmc -c "system configuration save"

    echo "✅ Proxy0 успешно создан и сохранён (проверка не была включена или пропущена)!"
fi

rm "$0"
