#!/bin/sh
#установка производится командой:
#   opkg update && \
opkg install curl wget wget-ssl coreutils-df procps-ng-free procps-ng-uptime && \
curl -fsSL -o /opt/etc/custom-banner.sh https://raw.githubusercontent.com/pegakmop/pegakmop.github.io/refs/heads/main/entware/custom-banner.sh && \
chmod +x /opt/etc/custom-banner.sh && \
grep -qxF '/opt/etc/custom-banner.sh' ~/.profile || echo '/opt/etc/custom-banner.sh' >> ~/.profile
. /opt/etc/profile

# удаление производится командой:
#   rm -rf /opt/etc/custom-banner.sh 

# PROMPT
# colors

blk="\033[1;30m"   # Black
red="\033[1;31m"   # Red
grn="\033[1;32m"   # Green
ylw="\033[1;33m"   # Yellow
blu="\033[1;34m"   # Blue
pur="\033[1;35m"   # Purple
cyn="\033[1;36m"   # Cyan
wht="\033[1;37m"   # White
clr="\033[0m"      # Reset

print_menu() {
  # Очистка экрана
  printf "\033c"
  
  # Установка цвета текста (если переменная CYAN определена)
  printf "${blu}"

  # Вывод текста в многострочном формате
  cat << 'EOF'
                        _______   _________       _____    ____  ______
                       / ____/ | / /_  __/ |     / /   |  / __ \/ ____/
                      / __/ /  |/ / / /  | | /| / / /| | / /_/ / __/
                     / /___/ /|  / / /   | |/ |/ / ___ |/ _, _/ /___
                    /_____/_/ |_/ /_/    |__/|__/_/  |_/_/ |_/_____/
EOF
}

# Вызов баннера
print_menu

# Установка приглашения
sh_prompt() {
    PS1=${cyn}' \w '${grn}' \$ '${clr}
}
sh_prompt

# Обновление списка пакетов
opkg update > /dev/null 2>&1

# Определение типа CPU
_CPU_TYPE="$(cat /proc/cpuinfo | awk -F: '/(model|system)/{print $2}' | head -1 | sed 's, ,,')"

if [ "$(uname -m)" = "aarch64" ]; then
    CPU_TYPE="$_CPU_TYPE"
else
    CPU_TYPE="$_CPU_TYPE$(cat /proc/cpuinfo | awk -F: '/cpu model/{print $2}' | head -1)"
fi

# Получение внешнего IP
EXT_IP="$(curl -s https://ipinfo.io/ip 2>/dev/null || echo 'N/A')"

# Основной вывод
printf "\n"
printf "   ${wht} %-10s ${ylw} %-30s ${wht} %-10s ${ylw}    %-30s ${clr}\n" \
    "Date:" "📆 $(date)" \
    "Uptime:" "🕐 $(uptime -p)"
printf "   ${wht} %-10s ${blu} %-30s ${wht} %-10s ${blu}  %-30s ${clr}\n" \
    "Router:" "$(ndmc -c "show version" 2>/dev/null | awk -F": " '/model/ {print $2}')" \
    "Accessed IP:" "$EXT_IP"
printf "   ${wht} %-10s ${grn} %-30s ${wht}   %-10s ${grn}    %-30s ${clr}\n" \
    "OS:" "$(uname -s) 🐧" \
    "CPU:" "$CPU_TYPE"
printf "   ${wht} %-10s ${grn} %-30s ${wht} %-10s ${grn} %-30s ${clr}\n" \
    "Kernel:" "$(uname -r)" \
    "Architecture:" "$(uname -m)"

# Температура CPU — только если доступен файл
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    CPU_TEMP_C=$(cat /sys/class/thermal/thermal_zone0/temp)
    if echo "$CPU_TEMP_C" | grep -Eq '^[0-9]+$'; then
        CPU_TEMP="$(($CPU_TEMP_C / 1000))°C"
        printf "   ${wht} %-10s ${red} %-30s ${clr}\n" \
            "CPU Temp:" "$CPU_TEMP"
    fi
fi

# Остальная информация
printf "   ${wht} %-10s ${pur} %-30s ${clr}\n" \
    "Disk:" "$(df -h | grep '/opt' | awk '{print $2" (size) / "$3" (used) / "$4" (free) / "$5" (used %) : 💾 "$6}')"
printf "   ${wht} %-10s ${pur} %-30s ${clr}\n" \
    "Memory:" "$(free -h --mega | awk '/Mem/{print $2" (total) / "$3" (used) / "$4" (free)"}')"
printf "   ${wht} %-10s ${pur} %-30s ${clr}\n" \
    "Swap:" "$(free -h --mega | awk '/Swap/{print $2" (total) / "$3" (used) / "$4" (free)"}')"
printf "   ${wht} %-10s ${pur} %-30s ${clr}\n" \
    "LA:" "$(cat /proc/loadavg | awk '{print $1" (1m) / "$2" (5m) / "$3" (15m)"}')"
printf "   ${wht} %-10s ${red} %-30s ${wht}\n" \
    "User:" "🤵 $(echo $USER)"

# Версия Entware
if [ -f "/opt/etc/entware_release" ]; then
    printf "   ${wht} %-10s ${grn} %-30s ${clr}\n" \
        "Dist:" "$(awk -F= '/^PRETTY_NAME/ {gsub(/"/, "", $2); print $2}' /opt/etc/entware_release)"
else
    printf "   ${wht} %-10s ${grn} %-30s ${clr}\n" \
        "Dist:" "Entware"
fi

# Установленные пакеты и обновления
printf "   ${wht} %-10s ${cyn} %-30s ${wht}     %-10s ${cyn} %-30s ${clr}\n" \
    "Installed:" "📦📦 $(opkg list-installed | wc -l)" \
    "Upgrade:" "📦 $(opkg list-upgradable | wc -l)"
printf "\n"
