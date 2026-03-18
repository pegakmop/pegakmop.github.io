#!/bin/sh

. /opt/etc/profile

# ===== Цвета =====
blk="\033[1;30m"
red="\033[1;31m"
grn="\033[1;32m"
ylw="\033[1;33m"
blu="\033[1;34m"
pur="\033[1;35m"
cyn="\033[1;36m"
wht="\033[1;37m"
clr="\033[0m"

# ===== Очистка экрана и баннер =====
printf "\033c"
printf "${blu}"
cat << 'EOF'
            _______   _________       _____    ____  ______
           / ____/ | / /_  __/ |     / /   |  / __ \/ ____/
          / __/ /  |/ / / /  | | /| / / /| | / /_/ / __/
         / /___/ /|  / / /   | |/ |/ / ___ |/ _, _/ /___
        /_____/_/ |_/ /_/    |__/|__/_/  |_/_/ |_/_____/
EOF
printf "${clr}\n"
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
  TEMP="$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))°C"
else
  TEMP="N/A"
fi
ROUTER_MODEL="$(
  ndmc -c "show version" 2>/dev/null \
  | awk -F": " '/model/ {print $2}'
)"

# ===== Проверка сервисов =====
check_service() {
  if pidof "$1" >/dev/null 2>&1; then
    printf "🟢 %-12s ${grn}running${clr}\n" "$1"
  else
    printf "🔴 %-12s ${red}stopped${clr}\n" "$1"
  fi
}

# ===== Вывод =====
print_info() {
  printf "Ваша модель роутера: $ROUTER_MODEL и его температура $TEMP"
  echo
  echo
  printf "${ylw}🔧 Состояние сервисов на роутере:${clr}\n"
  check_service x-ui
  check_service neofit
  check_service xray
  check_service sing-box
  check_service lighttpd
  check_service hrweb
  check_service hrneo
  check_service mihomo
  check_service AdGuardHome
}

print_info
echo
echo
echo
