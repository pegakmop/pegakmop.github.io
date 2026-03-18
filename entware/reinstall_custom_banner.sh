#!/bin/sh

while true; do
    echo "Выберите действие:"
    echo "1) Установить banner Full"
    echo "2) Установить banner Medium"
    echo "3) Установить banner Lite"
    echo "4) Удалить"
    echo "5) Выйти"
    printf "Введите номер действия: "
    read -r choice

    case "$choice" in
        1)
            echo "Выполняется Full установка..."
            opkg update && \
            opkg install curl wget wget-ssl coreutils-df procps-ng-free procps-ng-uptime && \
            curl -fsSL -o /opt/etc/custom-banner.sh https://raw.githubusercontent.com/pegakmop/pegakmop.github.io/refs/heads/main/entware/custom-banner0.sh && \
            chmod +x /opt/etc/custom-banner.sh && \
            grep -qxF '/opt/etc/custom-banner.sh' ~/.profile || echo '/opt/etc/custom-banner.sh' >> ~/.profile
            echo "Установка завершена."
            ;;
        2)
            echo "Выполняется Medium установка..."
            opkg update && \
            opkg install curl wget wget-ssl coreutils-df procps-ng-free procps-ng-uptime && \
            curl -fsSL -o /opt/etc/custom-banner.sh https://raw.githubusercontent.com/pegakmop/pegakmop.github.io/refs/heads/main/entware/custom-banner1.sh && \
            chmod +x /opt/etc/custom-banner.sh && \
            grep -qxF '/opt/etc/custom-banner.sh' ~/.profile || echo '/opt/etc/custom-banner.sh' >> ~/.profile
            echo "Установка завершена."
            ;;
        3)
            echo "Выполняется Lite установка..."
            opkg update && \
            opkg install curl wget wget-ssl coreutils-df procps-ng-free procps-ng-uptime && \
            curl -fsSL -o /opt/etc/custom-banner.sh https://raw.githubusercontent.com/pegakmop/pegakmop.github.io/refs/heads/main/entware/custom-banner2.sh && \
            chmod +x /opt/etc/custom-banner.sh && \
            grep -qxF '/opt/etc/custom-banner.sh' ~/.profile || echo '/opt/etc/custom-banner.sh' >> ~/.profile
            echo "Установка завершена."
            ;;
        4)
            echo "Выполняется удаление..."
            rm -f /opt/etc/custom-banner.sh
            sed -i '/\/opt\/etc\/custom-banner\.sh/d' ~/.profile
            echo "Удаление завершено."
            ;;
        5)
            echo "Выход."
            exit 0
            ;;
        *)
            echo "Некорректный ввод, попробуйте ещё раз."
            ;;
    esac
done
