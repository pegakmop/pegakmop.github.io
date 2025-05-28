#!/bin/sh
echo "смотреть в репозитории автора: https://qp-io.github.io/magitricle-skin"
echo "Выберите действие:"
echo "1) Установить skin поверх стандартного (замена)"
echo "2) Установить как отдельный skin (qp)"
echo "3) Восстановить стандартный skin"
echo "4) Удалить отдельный skin (qp) и вернуть стандартный"
read -p "Введите номер действия (1-4): " choice

case "$choice" in
  1)
    echo "Установка поверх стандартного скина..."
    opkg update && opkg install curl
    if [ -f /opt/usr/share/magitrickle/skins/default/index.html ]; then
      mv /opt/usr/share/magitrickle/skins/default/index.html /opt/usr/share/magitrickle/skins/default/index_stok.html
    fi
    curl -L -o /opt/usr/share/magitrickle/skins/default/index.html https://github.com/qp-io/qp-io.github.io/raw/refs/heads/main/mtskin.html
    echo "Скин установлен поверх стандартного."
    ;;

  2)
    echo "Установка как отдельного скина (qp)..."
    opkg update && opkg install curl
    mkdir -p /opt/usr/share/magitrickle/skins/qp
    curl -L -o /opt/usr/share/magitrickle/skins/qp/index.html https://github.com/qp-io/qp-io.github.io/raw/refs/heads/main/mtskin.html
    sed -i 's/skin: default/skin: qp/' /opt/var/lib/magitrickle/config.yaml
    /opt/etc/init.d/S99magitrickle reconfigure
    echo "Скин установлен как отдельный (qp)."
    ;;

  3)
    echo "Восстановление стандартного скина после замены..."
    if [ -f /opt/usr/share/magitrickle/skins/default/index_stok.html ]; then
      mv /opt/usr/share/magitrickle/skins/default/index_stok.html /opt/usr/share/magitrickle/skins/default/index.html
      echo "Скин восстановлен."
    else
      echo "Файл оригинального скина не найден."
    fi
    ;;

  4)
    echo "Удаление отдельного скина (qp) и возврат к стандартному..."
    sed -i 's/skin: qp/skin: default/' /opt/var/lib/magitrickle/config.yaml
    /opt/etc/init.d/S99magitrickle reconfigure
    rm -rf /opt/usr/share/magitrickle/skins/qp
    echo "Скин qp удалён и восстановлен стандартный."
    ;;

  *)
    echo "Неверный выбор."
    ;;
esac
