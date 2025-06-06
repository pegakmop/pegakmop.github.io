#!/bin/sh

# ====== Получение следующего доступного номера интерфейса Wireguard ======
interfaces=$(ls /sys/class/net/ | grep '^nwg[0-9]\+$')

if [ -z "$interfaces" ]; then
    iface_num=0
else
    max=$(echo "$interfaces" | sed 's/nwg//' | sort -n | tail -n1)
    iface_num=$((max + 1))
fi

iface_name="Wireguard$iface_num"
echo "Получили свободный интерфейс: $iface_name"
# ====== Генерация случайного байта (0-255) ======
rand_byte() {
  hexdump -n 1 -e '/1 "%u"' /dev/urandom
}

# ====== Генерация случайного IP-адреса ======
generate_ip() {
  n=$(rand_byte)
  n=$((n % 2))  # Ограничиваем выбор до двух вариантов
  case $n in
    0) ip="188.114.96" ;;
    1) ip="188.114.97" ;;
  esac

  last_octet=$(rand_byte)
  echo "$ip.$((last_octet % 256))"
}

# ====== Генерация случайного порта ======
generate_port() {
  ports="500 854 859 864 878 880 890 891 894 903 908 928 934 939 942 943 945 946 955 968 987 988 1002 1010 1014 1018 1070 1074 1180 1387 1701 1843 2371 2408 2506 3138 3476 3581 3854 4177 4198 4233 4500 5279 5956 7103 7152 7156 7281 7559 8319 8742 8854 8886"
  count=$(echo "$ports" | wc -w)
  rand_index=$(rand_byte)
  index=$(( (rand_index % count) + 1 ))
  echo "$ports" | cut -d' ' -f"$index"
}

# ====== Генерация случайного локального IP-адреса ======
generate_local_ip() {
  last_octet=$(rand_byte)
  last_octet=$(( (last_octet % 255) + 1 ))  # от 1 до 255
  echo "172.16.0.$last_octet/32"
}

# ====== Генерация всех параметров ======
peer_ip=$(generate_ip)
peer_port=$(generate_port)
local_ip=$(generate_local_ip)
echo "Генерируем конфиг WG"
# ====== Конфигурация WireGuard-интерфейса через ndmc для роутеров keenetic ======
configure_wireguard() {
  ndmc -c "interface $iface_name"
  ndmc -c "interface $iface_name description @pegakmop-$iface_name"
  ndmc -c "interface $iface_name ip address $local_ip"
  ndmc -c "interface $iface_name wireguard private-key CHSL4T1CxVhMoah1SgDQyc7QFgl4bZw/QaHQc3lopUg="
  ndmc -c "interface $iface_name wireguard listen-port 2408"
  ndmc -c "interface $iface_name wireguard peer bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="
  #ndmc -c "interface $iface_name wireguard peer bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo= description Cloudflare-WARP"
  ndmc -c "interface $iface_name wireguard peer bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo= allow-ips 0.0.0.0/0"
  ndmc -c "interface $iface_name wireguard peer bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo= endpoint $peer_ip:$peer_port"
  ndmc -c "interface $iface_name wireguard peer bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo= keepalive-interval 30"
  ndmc -c 'system configuration save'
  ndmc -c "interface $iface_name up"
}
echo "Закидываем конфиг на роутер кинетик"
# ====== Запуск настройки ======
if configure_wireguard; then
  echo "Автор скрипта @pegakmop и против изменений в скрипте"
  echo "Локальный IP: $local_ip"
  echo "Пир: $peer_ip:$peer_port"
  echo "Для генерации нового конфига введи команду в терминале:    ./pegakmop.sh"
  echo "Интерфейс $iface_name настроен и запущен!"
else
  echo "Ошибка при настройке интерфейса $iface_name! на роутере"
  exit 1
fi
