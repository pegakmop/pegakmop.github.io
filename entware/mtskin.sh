#!/bin/sh
echo "смотреть в репозитории автора: https://qp-io.github.io/magitricle-skin"
echo "Выберите режим:"
echo "1) Работа с заменой стандартного скина"
echo "2) Работа с отдельным скином (qp)"
echo "0) Выход"
read -p "Введите номер режима (0-2): " mode

case "$mode" in
  1)
    echo "Вы выбрали: Замена стандартного скина"
    echo "1) Установить кастомный скин (заменить стандартный)"
    echo "2) Восстановить оригинальный стандартный скин"
    echo "0) Отмена"
    read -p "Введите действие (0-2): " action

    case "$action" in
      1)
        echo "Установка кастомного скина..."
        opkg update && opkg install curl
        if [ -f /opt/usr/share/magitrickle/skins/default/index.html ]; then
          mv /opt/usr/share/magitrickle/skins/default/index.html /opt/usr/share/magitrickle/skins/default/index_stok.html
        fi
        curl -L -o /opt/usr/share/magitrickle/skins/default/index.html https://github.com/qp-io/qp-io.github.io/raw/refs/heads/main/mtskin.html
        echo "Скин установлен поверх стандартного."
        ;;
      2)
        echo "Восстановление оригинального стандартного скина..."
        if [ -f /opt/usr/share/magitrickle/skins/default/index_stok.html ]; then
          mv /opt/usr/share/magitrickle/skins/default/index_stok.html /opt/usr/share/magitrickle/skins/default/index.html
          echo "Скин восстановлен."
        else
          echo "Файл оригинального скина не найден."
        fi
        ;;
      0)
        echo "Отмена действия."
        ;;
      *)
        echo "Неверный выбор действия."
        ;;
    esac
    ;;

  2)
    echo "Вы выбрали: Отдельный скин (qp)"
    echo "1) Установить скин как отдельный (qp)"
    echo "2) Удалить qp и вернуть стандартный"
    echo "0) Отмена"
    read -p "Введите действие (0-2): " action

    case "$action" in
      1)
        echo "Установка отдельного скина (qp)..."
        opkg update && opkg install curl
        mkdir -p /opt/usr/share/magitrickle/skins/qp
        curl -L -o /opt/usr/share/magitrickle/skins/qp/index.html https://github.com/qp-io/qp-io.github.io/raw/refs/heads/main/mtskin.html
        sed -i 's/skin: default/skin: qp/' /opt/var/lib/magitrickle/config.yaml
        /opt/etc/init.d/S99magitrickle reconfigure
        echo "Отдельный скин установлен и активирован."
        ;;
      2)
        echo "Удаление qp и возврат к стандартному..."
        sed -i 's/skin: qp/skin: default/' /opt/var/lib/magitrickle/config.yaml
        /opt/etc/init.d/S99magitrickle reconfigure
        rm -rf /opt/usr/share/magitrickle/skins/qp
        echo "Скин qp удалён, возвращён стандартный."
        ;;
      0)
        echo "Отмена действия."
        ;;
      *)
        echo "Неверный выбор действия."
        ;;
    esac
    ;;

  0)
    echo "Выход."
    ;;

  *)
    echo "Неверный выбор режима."
    ;;
esac
