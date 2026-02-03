#!/bin/sh

# Скрипт для форматирования раздела под Entware на Keenetic
# Автор: @pegakmop

# Функции для цветного вывода
print_red() { printf "\033[0;31m%s\033[0m\n" "$1"; }
print_green() { printf "\033[0;32m%s\033[0m\n" "$1"; }
print_yellow() { printf "\033[1;33m%s\033[0m\n" "$1"; }
print_blue() { printf "\033[0;34m%s\033[0m\n" "$1"; }

echo ""
print_green "══════════════════════════════════════════════════════════════"
print_green "   Скрипт форматирования раздела для Entware от @pegakmop"
print_green "══════════════════════════════════════════════════════════════"
echo ""

# Определение активного раздела Entware
get_active_entware() {
    ENTWARE_MOUNT=$(mount | grep " /opt " | awk '{print $1}')
    if [ -n "$ENTWARE_MOUNT" ]; then
        echo "$ENTWARE_MOUNT" | sed 's|/dev/||'
    else
        echo ""
    fi
}

# Получить метку раздела
get_partition_label() {
    DEVICE=$1
    LABEL=$(blkid "$DEVICE" 2>/dev/null | grep -o 'LABEL="[^"]*"' | cut -d'"' -f2)
    if [ -n "$LABEL" ]; then
        echo "$LABEL"
    else
        echo "Entware"
    fi
}

# Проверка наличия tune2fs
check_dependencies() {
    print_yellow "Проверка зависимостей..."
    if ! command -v tune2fs >/dev/null 2>&1; then
        print_yellow "tune2fs не найден. Устанавливаю..."
        opkg update
        opkg install tune2fs
        if [ $? -eq 0 ]; then
            print_green "✓ tune2fs успешно установлен!"
        else
            print_red "✗ Ошибка установки tune2fs!"
            exit 1
        fi
    else
        print_green "✓ tune2fs уже установлен."
    fi
    echo ""
}

# Создать список разделов
create_partition_list() {
    ACTIVE_ENTWARE=$1
    TEMP_FILE="/tmp/partition_list_$$"
    
    cat /proc/partitions | grep -E "sd|mmcblk" | sort -k4 | while read line; do
        PARTITION=$(echo "$line" | awk '{print $4}')
        if [ "$PARTITION" != "$ACTIVE_ENTWARE" ] && [ -n "$PARTITION" ]; then
            echo "$PARTITION"
        fi
    done > "$TEMP_FILE"
    
    echo "$TEMP_FILE"
}

# Показать доступные разделы
show_partitions() {
    ACTIVE_ENTWARE=$1
    
    print_green "Доступные разделы для форматирования:"
    echo "─────────────────────────────────────────"
    
    NUM=1
    cat /proc/partitions | grep -E "sd|mmcblk" | sort -k4 | while read line; do
        PARTITION=$(echo "$line" | awk '{print $4}')
        SIZE=$(echo "$line" | awk '{printf "%10s MB", int($3/1024)}')
        
        if [ "$PARTITION" = "$ACTIVE_ENTWARE" ]; then
            continue
        elif [ -n "$PARTITION" ]; then
            printf "  %2d) %-10s %s\n" "$NUM" "$PARTITION" "$SIZE"
            NUM=$((NUM + 1))
        fi
    done
    
    echo "─────────────────────────────────────────"
    echo ""
}

# Показать смонтированные разделы
show_mounted() {
    ACTIVE_ENTWARE=$1
    
    print_yellow "Смонтированные разделы:"
    mount | grep -E "sd|mmcblk" | sort -t' ' -k1 | while read line; do
        DEVICE=$(echo "$line" | awk '{print $1}')
        MOUNT_POINT=$(echo "$line" | awk '{print $3}')
        PARTITION=$(echo "$DEVICE" | sed 's|/dev/||')
        
        if [ "$PARTITION" = "$ACTIVE_ENTWARE" ]; then
            print_red "  $DEVICE -> $MOUNT_POINT [АКТИВНЫЙ ENTWARE - ЗАЩИЩЕН]"
        else
            echo "  $DEVICE -> $MOUNT_POINT"
        fi
    done
    echo ""
}

# Получить точку монтирования раздела
get_mount_point() {
    mount | grep "^$1 " | awk '{print $3}'
}

# Монтирование раздела
mount_partition() {
    DEVICE=$1
    LABEL=$2
    
    print_yellow "Монтирую раздел $DEVICE..."
    
    MOUNT_DIR="/tmp/mnt/$LABEL"
    mkdir -p "$MOUNT_DIR"
    
    mount "$DEVICE" "$MOUNT_DIR" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_green "✓ Раздел смонтирован в: $MOUNT_DIR"
        return 0
    else
        print_red "✗ Ошибка монтирования!"
        return 1
    fi
}

# Основная функция
main() {
    # Определяем активный раздел Entware
    ACTIVE_ENTWARE=$(get_active_entware)
    
    if [ -n "$ACTIVE_ENTWARE" ]; then
        printf "\033[0;34mОбнаружен активный Entware на разделе: \033[0;31m%s\033[0m\n" "$ACTIVE_ENTWARE"
        print_blue "Этот раздел будет защищен от форматирования."
        echo ""
    else
        print_yellow "Активный Entware не обнаружен."
        echo ""
    fi
    
    # Проверка зависимостей
    check_dependencies
    
    # Создаем список разделов
    PARTITION_LIST_FILE=$(create_partition_list "$ACTIVE_ENTWARE")
    
    # Показать разделы
    show_partitions "$ACTIVE_ENTWARE"
    show_mounted "$ACTIVE_ENTWARE"
    
    # Подсчитываем количество доступных разделов
    PARTITION_COUNT=$(wc -l < "$PARTITION_LIST_FILE")
    
    if [ "$PARTITION_COUNT" -eq 0 ]; then
        print_red "Нет доступных разделов для форматирования!"
        rm -f "$PARTITION_LIST_FILE"
        exit 1
    fi
    
    # Запрос номера раздела
    printf "\033[1;33mВведите номер раздела (1-$PARTITION_COUNT): \033[0m"
    read PARTITION_NUM
    
    # Проверка корректности ввода
    if ! echo "$PARTITION_NUM" | grep -qE '^[0-9]+$' || [ "$PARTITION_NUM" -lt 1 ] || [ "$PARTITION_NUM" -gt "$PARTITION_COUNT" ]; then
        print_red "Ошибка: введите число от 1 до $PARTITION_COUNT"
        rm -f "$PARTITION_LIST_FILE"
        exit 1
    fi
    
    # Получаем имя раздела по номеру
    PARTITION=$(sed -n "${PARTITION_NUM}p" "$PARTITION_LIST_FILE")
    rm -f "$PARTITION_LIST_FILE"
    
    if [ -z "$PARTITION" ]; then
        print_red "Ошибка: не удалось определить раздел!"
        exit 1
    fi
    
    DEVICE="/dev/$PARTITION"
    
    # Получаем текущую метку раздела
    LABEL=$(get_partition_label "$DEVICE")
    
    # Проверка монтирования
    MOUNT_POINT=$(get_mount_point "$DEVICE")
    
    # Выбор типа форматирования
    echo ""
    print_yellow "Выберите тип форматирования:"
    echo "  1) С журналированием (безопаснее, медленнее)"
    echo "  2) Без журналирования (быстрее, риск потери данных)"
    printf "\033[1;33mВаш выбор (1 или 2) [2]: \033[0m"
    read FORMAT_TYPE
    FORMAT_TYPE=${FORMAT_TYPE:-2}
    
    # Подтверждение
    echo ""
    print_red "╔════════════════════════════════════════════════╗"
    print_red "║  ВНИМАНИЕ! Все данные будут удалены!           ║"
    print_red "╚════════════════════════════════════════════════╝"
    print_red "Раздел: $DEVICE"
    print_red "Метка: $LABEL (сохранится)"
    if [ -n "$MOUNT_POINT" ]; then
        print_red "Смонтирован в: $MOUNT_POINT"
    fi
    if [ "$FORMAT_TYPE" = "2" ]; then
        print_red "Режим: БЕЗ журналирования"
    else
        print_red "Режим: С журналированием"
    fi
    echo ""
    printf "\033[1;33mФорматировать и смонтировать? (yes/no): \033[0m"
    read CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        print_yellow "Форматирование отменено."
        exit 0
    fi
    
    # Размонтирование если нужно
    if [ -n "$MOUNT_POINT" ]; then
        print_yellow "Размонтирую $DEVICE..."
        umount "$DEVICE" 2>/dev/null
        if [ $? -ne 0 ]; then
            print_red "Ошибка! Попытка принудительного размонтирования..."
            umount -f "$DEVICE" 2>/dev/null
            if [ $? -ne 0 ]; then
                print_red "Не удалось размонтировать раздел!"
                print_yellow "Проверьте процессы: lsof | grep $DEVICE"
                exit 1
            fi
        fi
        print_green "✓ Раздел размонтирован."
        sleep 1
    fi
    
    # Форматирование с автоматическим подтверждением
    echo ""
    print_yellow "Начинаю форматирование..."
    echo ""
    
    if [ "$FORMAT_TYPE" = "2" ]; then
        echo "y" | mkfs.ext4 -O^metadata_csum,^64bit,^orphan_file,^has_journal -b 4096 -m0 -L "$LABEL" "$DEVICE"
    else
        echo "y" | mkfs.ext4 -O^metadata_csum,^64bit,^orphan_file -b 4096 -m0 -L "$LABEL" "$DEVICE"
    fi
    
    if [ $? -eq 0 ]; then
        echo ""
        print_green "╔════════════════════════════════════════════════╗"
        print_green "║  ✓ Форматирование успешно завершено!          ║"
        print_green "╚════════════════════════════════════════════════╝"
        
        # Автоматическое монтирование
        mount_partition "$DEVICE" "$LABEL"
        echo ""
        print_yellow "Теперь можно развернуть Entware на этом разделе."
        echo ""
    else
        print_red "✗ Ошибка форматирования!"
        exit 1
    fi
}

# Запуск
main
