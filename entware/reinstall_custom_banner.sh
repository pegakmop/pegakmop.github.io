#!/bin/sh

while true; do
    echo "Выберите действие:"
    echo "1) Установить"
    echo "2) Удалить"
    echo "3) Выйти"
    printf "Введите номер действия: "
    read -r choice

    case "$choice" in
        1)
            echo "Выполняется установка..."
            opkg update && \
            opkg install curl wget wget-ssl coreutils-df procps-ng-free procps-ng-uptime && \
            curl -fsSL -o /opt/etc/custom-banner.sh https://raw.githubusercontent.com/pegakmop/pegakmop.github.io/refs/heads/main/entware/custom-banner.sh && \
            chmod +x /opt/etc/custom-banner.sh && \
            grep -qxF '/opt/etc/custom-banner.sh' ~/.profile || echo '/opt/etc/custom-banner.sh' >> ~/.profile
            echo "Установка завершена."
            ;;
        2)
            echo "Выполняется удаление..."
            rm -f /opt/etc/custom-banner.sh
            sed -i '/\/opt\/etc\/custom-banner\.sh/d' ~/.profile
            echo "Удаление завершено."
            ;;
        3)
            echo "Выход."
            exit 0
            ;;
        *)
            echo "Некорректный ввод, попробуйте ещё раз."
            ;;
    esac
done
