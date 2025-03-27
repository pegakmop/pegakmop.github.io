#!/bin/sh
chmod +x "$0"

# Проверка наличия iputils-ping и установка, если нет
if ! command -v ping >/dev/null 2>&1; then
    echo "Устанавливаем iputils-ping..."
    opkg update && opkg install iputils-ping
fi

TARGET_HOST="ya.ru"
MAX_SIZE=1500
MIN_SIZE=800

# Поиск активного интернет-интерфейса
for IFACE in $(ip route | awk '/^default/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}'); do
    echo "Проверка интерфейса: $IFACE"
    [ "$(cat /sys/class/net/$IFACE/operstate 2>/dev/null)" = "up" ] && {
        echo "Используется интерфейс: $IFACE"
        SELECTED_IFACE="$IFACE"
        break
    }
done

[ -z "$SELECTED_IFACE" ] && { echo "Ошибка: нет активного интерфейса"; exit 1; }

echo ""
echo " Целевой хост для пинга: $TARGET_HOST"
echo " Интерфейс: $SELECTED_IFACE"
echo ""

# Функция для проверки MSS
check_mss() {
    SIZE="$1"
    echo "DEBUG: ping -c 1 -W 1 -s $SIZE -M do -I $SELECTED_IFACE $TARGET_HOST"
    ping -c 1 -W 1 -s "$SIZE" -M do -I "$SELECTED_IFACE" "$TARGET_HOST" > /dev/null 2>&1
    return $?
}

# Начинаем с максимального размера и уменьшаем, пока не найдём работающий
BEST_MSS=0
for MSS in $(seq $MAX_SIZE -10 $MIN_SIZE); do
    echo " - Пробуем MSS = $MSS"
    if check_mss "$MSS"; then
        BEST_MSS="$MSS"
        break
    fi
done

# Проверка, найден ли корректный MSS
if [ "$BEST_MSS" -eq 0 ]; then
    echo "Ошибка: не удалось определить MSS"
    exit 1
fi

# Вычисляем MTU
MTU=$((BEST_MSS + 28))

echo ""
echo " Максимальный MSS без фрагментации: $BEST_MSS"
echo " Оптимальный MTU = $MTU"
