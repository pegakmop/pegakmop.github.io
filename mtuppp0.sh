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

echo "Поиск PPP-интерфейса, который проходит тест MSS..."

# Функция для проверки MSS
check_mss() {
    SIZE="$1"
    echo "DEBUG: ping -c 1 -W 1 -s $SIZE -M do -I $IFACE $TARGET_HOST"
    ping -c 1 -W 1 -s "$SIZE" -M do -I "$IFACE" "$TARGET_HOST" > /dev/null 2>&1
    return $?
}

# Функция теста интерфейса
test_iface() {
    IFACE="$1"
    echo "Проверка интерфейса: $IFACE"

    # Проверяем, есть ли у интерфейса IP-адрес
    if ! ip addr show dev "$IFACE" | grep -q 'inet '; then
        echo " - Пропущен (нет IP-адреса)"
        return 1
    fi

    # Проверяем MSS
    for MSS in $(seq $MAX_SIZE -10 $MIN_SIZE); do
        echo " - Пробуем MSS = $MSS"
        if check_mss "$MSS"; then
            echo "✅ Интерфейс $IFACE прошел тест с MSS = $MSS"
            SELECTED_IFACE="$IFACE"
            BEST_MSS="$MSS"
            return 0
        fi
    done

    echo " - Интерфейс $IFACE не проходит тест MSS"
    return 1
}

# Проверяем PPP-интерфейсы
SELECTED_IFACE=""
BEST_MSS=0
for IFACE in $(ip -o link show | awk -F': ' '{print $2}' | grep -E "^ppp[0-9]*$"); do
    test_iface "$IFACE" && break
done

# Если PPP-интерфейсы не подошли, ищем другие
if [ -z "$SELECTED_IFACE" ]; then
    echo "PPP не прошли тест, пробуем другие интерфейсы..."

    for IFACE in $(ip route | awk '/^default/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}'); do
        echo "Проверка интерфейса: $IFACE"

        # Исключаем ненужные интерфейсы
        echo "$IFACE" | grep -Eq "$EXCLUDE" && {
            echo " - Пропущен (в списке исключений)"
            continue
        }

        # Проверяем активность
        [ "$(cat /sys/class/net/$IFACE/operstate 2>/dev/null)" = "up" ] || {
            echo " - Пропущен (неактивен)"
            continue
        }

        test_iface "$IFACE" && break
    done
fi

# Ошибка, если подходящего интерфейса нет
if [ -z "$SELECTED_IFACE" ]; then
    echo "Не найден подходящий интерфейс для выхода в интернет."
    exit 1
fi

# Вычисляем MTU
MTU=$((BEST_MSS + 28))

echo ""
echo "Выбран интерфейс: $SELECTED_IFACE"
echo "Максимальный MSS без фрагментации: $BEST_MSS"
echo "Оптимальный MTU = $MTU"
