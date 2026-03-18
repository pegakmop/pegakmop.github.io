#!/bin/sh

. /opt/etc/profile

# Цвета
blk="\033[1;30m"; red="\033[1;31m"; grn="\033[1;32m"
ylw="\033[1;33m"; blu="\033[1;34m"; pur="\033[1;35m"
cyn="\033[1;36m"; wht="\033[1;37m"; clr="\033[0m"

# Очистка и баннер
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

# Обновление списка пакетов без вывода
opkg update > /dev/null 2>&1

# Сбор информации
EXT_IP="$(curl -s https://ipinfo.io/ip 2>/dev/null || echo 'N/A')"
NET_IFACE="$(ip -o -4 addr show | grep -v ' lo ' | awk '{print $2}' | head -n1)"
LOCAL_IP="$(ip -4 addr show dev "$NET_IFACE" | awk '/inet / {print $2}' | cut -d/ -f1)"
SSH_CONN="$(netstat -tn 2>/dev/null | grep ':222 ' | grep ESTABLISHED | wc -l)"
LAST_BOOT="$(uptime -s 2>/dev/null || echo 'N/A')"

# CPU и температура
_CPU_TYPE="$(awk -F: '/(model|system)/{print $2}' /proc/cpuinfo | head -1 | sed 's, ,,')"
CPU_TYPE="$_CPU_TYPE$(awk -F: '/cpu model/{print $2}' /proc/cpuinfo | head -1)"
CORES="$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo '?')"
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
  TEMP="$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))°C"
else
  TEMP="not support"
fi

# Память и диск
MEMORY="$(free -h --mega | awk '/Mem/{print $2" (total) / "$3" (used) / "$4" (free)"}')"
SWAP="$(free -h --mega | awk '/Swap/{print $2" (total) / "$3" (used) / "$4" (free)"}')"
DISK_OPT="$(df -h | grep '/opt' | awk '{print $2" / "$3" / "$4" / "$5" : "$6}')"
LOAD_AVG="$(awk '{print $1" (1m) / "$2" (5m) / "$3" (15m)"}' /proc/loadavg)"
PROCS="$(ps | wc -l)"

# Entware версия
if [ -f "/opt/etc/entware_release" ]; then
  DISTRO="$(awk -F= '/^PRETTY_NAME/ {gsub(/"/, "", $2); print $2}' /opt/etc/entware_release)"
else
  DISTRO="Entware"
fi

INSTALLED="$(opkg list-installed 2>/dev/null | wc -l)"

# ===== Получаем список обновляемых пакетов =====
UPGRADABLE_LIST="$(opkg list-upgradable 2>/dev/null)"
UPGRADEABLE="$(echo "$UPGRADABLE_LIST" | grep -c . 2>/dev/null || echo 0)"
ROUTER_MODEL="$(ndmc -c "show version" | awk -F": " '/model/ {print $2}')"

# Вывод — одна колонка
print_info() {
  printf "📆 ${ylw}Date:${clr}           %s\n" "$(date)"
  printf "🕐 ${ylw}Uptime:${clr}         %s\n" "$(uptime -p)"
  printf "📡 ${ylw}Keenetic:${clr}       %s\n" "$ROUTER_MODEL"
  printf "🌍 ${ylw}External IP:${clr}    %s\n" "$EXT_IP"
  printf "🏠 ${cyn}Local IP:${clr}       %s\n" "$LOCAL_IP"
  printf "💻 ${grn}OS:${clr}             %s\n" "$(uname -s)"
  printf "🧠 ${grn}CPU:${clr}            %s\n" "$CPU_TYPE"
  printf "🔥 ${red}CPU Temp:${clr}       %s\n" "$TEMP"
  printf "🔢 ${grn}Cores:${clr}          %s\n" "$CORES"
  printf "💾 ${pur}Disk (/opt):${clr}    %s\n" "$DISK_OPT"
  printf "📈 ${pur}Memory:${clr}         %s\n" "$MEMORY"
  printf "📉 ${pur}Swap:${clr}           %s\n" "$SWAP"
  printf "📊 ${pur}Load Avg:${clr}       %s\n" "$LOAD_AVG"
  printf "⚙️ ${ylw}Processes:${clr}      %s\n" "$PROCS"
  printf "🔐 ${ylw}SSH Conn:${clr}       %s\n" "$SSH_CONN"
  printf "🔁 ${ylw}Last Boot:${clr}      %s\n" "$LAST_BOOT"
  printf "📦 ${grn}Installed:${clr}      %s\n" "$INSTALLED"
  printf "⬆️ ${red}Upgradable:${clr}     %s\n" "$UPGRADEABLE"
  printf "📦 ${grn}Distro:${clr}         %s\n" "$DISTRO"
  printf "${blk}Create entware menu for @pegakmop${clr}"
  echo
  echo
}

print_info
df -h | grep opt
echo
