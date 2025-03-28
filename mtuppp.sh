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

# Список исключаемых интерфейсов
EXCLUDE="^lo$|^wg[0-9]*$|^docker[0-9]*$|^br-.*$"

echo "Поиск активного интернет-интерфейса..."

# Поиск интерфейса с default-маршрутом
for IFACE in $(ip route | awk '/^default/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}'); do
    echo "Проверка интерфейса: $IFACE"

    # Если интерфейс ppp, пропускаем все проверки и используем его
    if echo "$IFACE" | grep -Eq "^ppp[0-9]*$"; then
        echo "Используется PPP-интерфейс: $IFACE"
        SELECTED_IFACE="$IFACE"
        break
    fi

    # Исключаем ненужные интерфейсы
    echo "$IFACE" | grep -Eq "$EXCLUDE" && {
        echo " - Пропущен (в списке исключений)"
        continue
    }

    # Проверка IP-адреса
    ip addr show dev "$IFACE" | grep -q 'inet ' || {
        echo " - Пропущен (нет IP-адреса)"
        continue
    }

    # Проверка активности
    [ "$(cat /sys/class/net/$IFACE/operstate 2>/dev/null)" = "up" ] || {
        echo " - Пропущен (неактивен)"
        continue
    }

    echo "Используется интерфейс: $IFACE"
    SELECTED_IFACE="$IFACE"
    break
done

# Ошибка, если подходящего интерфейса нет
if [ -z "$SELECTED_IFACE" ]; then
    echo "Не найден подходящий интерфейс для выхода в интернет."
    exit 1
fi

echo ""
echo "Целевой хост для пинга: $TARGET_HOST"
echo "Интерфейс: $SELECTED_IFACE"
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
echo "Максимальный MSS без фрагментации: $BEST_MSS"
echo "Оптимальный MTU = $MTU"
