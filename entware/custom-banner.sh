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

# ===== Обновление opkg (тихо) =====
opkg update >/dev/null 2>&1

# ===== Сеть =====
EXT_IP="$(curl -fs --max-time 3 https://ipinfo.io/ip 2>/dev/null || echo 'N/A')"

NET_IFACE="$(
  ip -o -4 addr show 2>/dev/null \
  | awk '!/ lo / {print $2; exit}'
)"

LOCAL_IP="$(
  ip -4 addr show dev "$NET_IFACE" 2>/dev/null \
  | awk '/inet / {print $2}' | cut -d/ -f1
)"

SSH_CONN="$(
  netstat -tn 2>/dev/null \
  | awk '$6=="ESTABLISHED" && $4~/:222$/ {c++} END{print c+0}'
)"

LAST_BOOT="$(uptime -s 2>/dev/null || echo 'N/A')"

# ===== CPU =====
CPU_TYPE="$(
  awk -F: '
    /(model name|system type|Processor)/ {
      gsub(/^[ \t]+/, "", $2)
      print $2
      exit
    }
  ' /proc/cpuinfo
)"

CORES="$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo '?')"

if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
  TEMP="$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))°C"
else
  TEMP="N/A"
fi

# ===== Память =====
MEMORY="$(
  free -h --mega 2>/dev/null \
  | awk '/Mem:/ {print $2" (total) / "$3" (used) / "$4" (free)"}'
)"

SWAP="$(
  free -h --mega 2>/dev/null \
  | awk '/Swap:/ {print $2" (total) / "$3" (used) / "$4" (free)"}'
)"

# ===== Диск =====
DISK_OPT="$(
  df -h 2>/dev/null \
  | awk '$6=="/opt" {print $2" / "$3" / "$4" / "$5" : "$6}'
)"

# ===== Система =====
LOAD_AVG="$(awk '{print $1" (1m) / "$2" (5m) / "$3" (15m)"}' /proc/loadavg)"

# ✅ Без ps → без WARNING
PROCS="$(ls /proc 2>/dev/null | grep -E '^[0-9]+$' | wc -l)"

# ===== Entware =====
if [ -f /opt/etc/entware_release ]; then
  DISTRO="$(
    awk -F= '/^PRETTY_NAME/ {
      gsub(/"/,"",$2); print $2
    }' /opt/etc/entware_release
  )"
else
  DISTRO="Entware"
fi

INSTALLED="$(opkg list-installed 2>/dev/null | wc -l)"
UPGRADEABLE="$(opkg list-upgradable 2>/dev/null | wc -l)"

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
  echo
  printf "${ylw}🔧 Running to install services:${clr}\n"
  check_service neofit
  check_service xray
  check_service sing-box
  check_service x-ui
  check_service hrweb
  check_service hrneo
}

print_info
