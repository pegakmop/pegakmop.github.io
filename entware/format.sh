#!/bin/sh

# Определяем текущий раздел с Entware (/opt)
ENTWARE_DEV=$(mount | grep 'on /opt ' | awk '{print $1}')
ENTWARE_UUID=$(blkid "$ENTWARE_DEV" | sed -n 's/.*UUID="\([^"]*\)".*/\1/p')
ENTWARE_LABEL=$(blkid "$ENTWARE_DEV" | sed -n 's/.*LABEL="\([^"]*\)".*/\1/p')
[ -z "$ENTWARE_LABEL" ] && ENTWARE_LABEL="(без метки)"
echo
echo "Скрипт для очистки одного из разделов(если их несколько) не затрагивает текущий активный entware"
echo
echo "Активный раздел с Entware: $ENTWARE_LABEL ($ENTWARE_DEV, UUID: $ENTWARE_UUID)"
echo
echo "Доступные разделы для очистки."
echo
# Поиск других разделов ext4, исключая Entware
i=1
for MNT in /tmp/mnt/*; do
    DEV=$(mount | grep "on $MNT " | awk '{print $1}')
    if [ -n "$DEV" ]; then
        UUID=$(blkid "$DEV" | sed -n 's/.*UUID="\([^"]*\)".*/\1/p')
        LABEL=$(blkid "$DEV" | sed -n 's/.*LABEL="\([^"]*\)".*/\1/p')
        [ -z "$LABEL" ] && LABEL="(без метки)"
        if [ "$UUID" != "$ENTWARE_UUID" ]; then
            echo "$i) $LABEL -> $MNT ($DEV)"
            eval OPTION_$i=\"$MNT\"
            i=$((i + 1))
        fi
    fi
done

if [ "$i" -eq 1 ]; then
    echo "Нет доступных разделов для очистки."
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
echo "Вы действительно хотите удалить ВСЁ содержимое раздела $SELECTED_MNT? [yes/NO]"
echo
read CONFIRM

if [ "$CONFIRM" = "yes" ]; then
    echo
    echo "Очистка $SELECTED_MNT..."
    rm -rf "$SELECTED_MNT"/*
    echo
    echo "Раздел очищен $SELECTED_MNT"
else
    echo
    echo "Операция отменена пользователем."
fi
