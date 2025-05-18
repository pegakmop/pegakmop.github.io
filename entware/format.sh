#!/bin/sh

# Получаем UUID раздела, смонтированного как /opt (где установлен Entware)
ENTWARE_DEV=$(mount | grep 'on /opt ' | awk '{print $1}')
ENTWARE_UUID=$(blkid "$ENTWARE_DEV" | sed -n 's/.*UUID="\([^"]*\)".*/\1/p')
echo "Данный скрипт предназначен для форматирования одного из нескольких разделов ext4 не включая раздел на котором сейчас entware"
echo "Текущий раздел Entware: $ENTWARE_DEV (UUID: $ENTWARE_UUID)"
echo

# Список доступных разделов
echo "Доступные разделы для очистки:"
AVAILABLE_PARTS=""
i=1

for MNT in /tmp/mnt/*; do
    DEV=$(mount | grep "on $MNT " | awk '{print $1}')
    if [ -n "$DEV" ]; then
        UUID=$(blkid "$DEV" | sed -n 's/.*UUID="\([^"]*\)".*/\1/p')
        LABEL=$(blkid "$DEV" | sed -n 's/.*LABEL="\([^"]*\)".*/\1/p')

        # Пропускаем, если это раздел с Entware
        if [ "$UUID" != "$ENTWARE_UUID" ]; then
            [ -z "$LABEL" ] && LABEL="(без метки)"
            echo "$i) $LABEL -> $MNT"
            eval OPTION_$i=\"$MNT\"
            i=$((i + 1))
        fi
    fi
done

if [ "$i" -eq 1 ]; then
    echo "Нет доступных разделов (все заняты или используется Entware)."
    exit 1
fi

echo
echo -n "Введите номер раздела для очистки: "
read SELECTED

SELECTED_MNT=$(eval echo \$OPTION_"$SELECTED")

if [ -z "$SELECTED_MNT" ]; then
    echo "Неверный выбор."
    exit 1
fi

echo
echo "Вы действительно хотите удалить ВСЁ содержимое из $SELECTED_MNT? [yes/NO]"
read CONFIRM

if [ "$CONFIRM" = "yes" ]; then
    echo "Очистка $SELECTED_MNT..."
    rm -rf "$SELECTED_MNT"/*
    echo "Раздел очищен."
else
    echo "Операция отменена."
fi
