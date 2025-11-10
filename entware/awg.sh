#!/bin/sh
echo "Приветствую всех запустивших и просматривающих скрипт, @pegakmop снова с вами, по всем вопросам пишите мне в телеграмм"
echo ""
echo "Данный скрипт представляет собой генерацию WARP конфигурации Cloudflare  и установку её на роутеры фирмы Keenetic при активной поддержке двух сайтов, если бы не они я бы и не стал заморачиваться с данным скриптом"
logger "Данный скрипт представляет собой генерацию WARP конфигурации Cloudflare  и установку её на роутеры фирмы Keenetic при активной поддержке двух сайтов, если бы не они я бы и не стал заморачиваться с данным скриптом"
echo ""

if ! opkg list-installed | grep -q '^jq '; then
    echo "Пакет jq не установлен. Устанавливаем..."
    ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net" >/dev/null 2>&1
    opkg update
    opkg install jq
else
    echo "jq уже установлен, это радует"
fi
echo ""
interfaces=$(ls /sys/class/net/ | grep '^nwg[0-9]\+$')
if [ -z "$interfaces" ]; then
    iface_num=0
else
    max=$(echo "$interfaces" | sed 's/nwg//' | sort -n | tail -n1)
    iface_num=$((max + 1))
fi
iface_name="Wireguard$iface_num"
configure_wireguard() {
  ndmc -c "no interface $iface_name" >/dev/null 2>&1
  ndmc -c "system configuration save" >/dev/null 2>&1
  echo "Устанавливаю конфигурацию на роутер..."
  logger "Устанавливаю конфигурацию на роутер..."
  logger "Возможно будет 1 или 2 ошибки красным гореть, не обращайте внимания на них, если у вас интернет только ip4, то это ошибки попытки добавления ip6 адресов. Если вы пользуетесь ip4 + ip6 ошибок не будет вообще."
  echo ""
  sleep 3
  ndmc -c "interface $iface_name" >/dev/null 2>&1
  ndmc -c "interface $iface_name description @pegakmop-$iface_name" >/dev/null 2>&1
  ndmc -c "interface $iface_name ip address $address_ip4/32" >/dev/null 2>&1
  ndmc -c "interface $iface_name ip address $address_ip6/128" >/dev/null 2>&1
  ndmc -c "interface $iface_name wireguard private-key $private_key" >/dev/null 2>&1
  ndmc -c "interface $iface_name wireguard listen-port $endpoint_port" >/dev/null 2>&1
  ndmc -c "interface $iface_name wireguard peer $public_key !AWG-ENTWARE" >/dev/null 2>&1
  ndmc -c "interface $iface_name wireguard peer $public_key allow-ips $allowed_ips_ip4" >/dev/null 2>&1
  ndmc -c "interface $iface_name wireguard peer $public_key allow-ips $allowed_ips_ip6" >/dev/null 2>&1
  ndmc -c "interface $iface_name wireguard peer $public_key endpoint $endpoint" >/dev/null 2>&1
  ndmc -c "interface $iface_name wireguard peer $public_key keepalive-interval 30" >/dev/null 2>&1
  ndmc -c "system configuration save" >/dev/null 2>&1
  ndmc -c "interface $iface_name up" >/dev/null 2>&1
  ndmc -c "interface $iface_name ip global 1" >/dev/null 2>&1
  ndmc -c "interface $iface_name wireguard asc $jc $jmin $jmax $s1 $s2 $h1 $h2 $h3 $h4" >/dev/null 2>&1
  ndmc -c "system configuration save" >/dev/null 2>&1
  echo "В веб-интерфейсе роутера на вкладке других подключений @pegakmop-$iface_name уже доступен."
  logger "В веб-интерфейсе роутера на вкладке других подключений @pegakmop-$iface_name уже доступен."
  echo ""
  echo "Вы всегда можете поддержать автора скрипта рублем на новые свершения задонатив ему на юмани кошелек 410012481566554"
  logger "Вы всегда можете поддержать автора скрипта рублем на новые свершения задонатив ему на юмани кошелек 410012481566554"
  echo ""
  echo "Установка конфигурации на роутер завершена."
  logger "Установка конфигурации на роутер завершена."
  echo ""
  echo "P.S. если генерируете более одного конфига и он не подключается, нажми на конфиг и смени ip 4 адрес с условного 172.16.0.2/32 на условно 172.16.0.3/32 или любой другой который тебе удобен и сохрани конфиг, не допустимо пересечение подсети между конфигурациями"
  logger "P.S. если генерируете более одного конфига и он не подключается, нажми на конфиг и смени ip 4 адрес с условного 172.16.0.2/32 на условно 172.16.0.3/32 или любой другой который тебе удобен и сохрани конфиг, не допустимо пересечение подсети между конфигурациями"
}


while true; do
  echo "Выберите источник генерации конфига:"
  echo "1 - warp-gen.vercel.app"
  read -r -p "Ваш выбор ответ цифрой (1): " choice

  case "$choice" in
    1)
      echo "Вы выбрали источник: warp-gen.vercel.app"
      response=$(curl -s https://warp-gen.vercel.app/generate-config)
      success=$(echo "$response" | jq -r '.success')

      if [ "$success" != "true" ]; then
        echo "Ошибка генерации конфига, попробуйте еще раз, либо вернитесь позднее, заодно напиши @pegakmop пусть проверит всё ли нормально."
        logger "Ошибка генерации конфига, попробуйте еще раз, либо вернитесь позднее, заодно напиши @pegakmop пусть проверит всё ли нормально."
        exit 1
      fi

      config=$(echo "$response" | jq -r '.config')
      cleaned_config=$(echo "$config" | grep -v -e '^\[Interface\]$' -e '^\[Peer\]$' -e '^$')
      break
      ;;
    *)
      echo "Неверный выбор. Пожалуйста, введите 1."
      ;;
  esac
done
echo ""
echo "Генерирую конфигурацию..."
logger "Генерирую конфигурацию..."
sleep 1
private_key=$(echo "$cleaned_config" | grep '^PrivateKey' | head -n1 | cut -d '=' -f2- | sed 's/^ *//;s/ *$//')
s1=$(echo "$cleaned_config" | grep '^S1' | head -n1 | cut -d '=' -f2- | sed 's/^ *//;s/ *$//')
s2=$(echo "$cleaned_config" | grep '^S2' | head -n1 | cut -d '=' -f2- | sed 's/^ *//;s/ *$//')
jc=$(echo "$cleaned_config" | grep '^Jc' | head -n1 | cut -d '=' -f2- | sed 's/^ *//;s/ *$//')
jmin=$(echo "$cleaned_config" | grep '^Jmin' | head -n1 | cut -d '=' -f2- | sed 's/^ *//;s/ *$//')
jmax=$(echo "$cleaned_config" | grep '^Jmax' | head -n1 | cut -d '=' -f2- | sed 's/^ *//;s/ *$//')
h1=$(echo "$cleaned_config" | grep '^H1' | head -n1 | cut -d '=' -f2- | sed 's/^ *//;s/ *$//')
h2=$(echo "$cleaned_config" | grep '^H2' | head -n1 | cut -d '=' -f2- | sed 's/^ *//;s/ *$//')
h3=$(echo "$cleaned_config" | grep '^H3' | head -n1 | cut -d '=' -f2- | sed 's/^ *//;s/ *$//')
h4=$(echo "$cleaned_config" | grep '^H4' | head -n1 | cut -d '=' -f2- | sed 's/^ *//;s/ *$//')
address=$(echo "$cleaned_config" | grep '^Address' | head -n1 | cut -d '=' -f2- | sed 's/^ *//;s/ *$//')
public_key=$(echo "$cleaned_config" | grep '^PublicKey' | head -n1 | cut -d '=' -f2- | sed 's/^ *//;s/ *$//')
allowed_ips=$(echo "$cleaned_config" | grep '^AllowedIPs' | head -n1 | cut -d '=' -f2- | sed 's/^ *//;s/ *$//')
endpoint=$(echo "$cleaned_config" | grep '^Endpoint' | head -n1 | cut -d '=' -f2- | sed 's/^ *//;s/ *$//')
endpoint_host=$(echo "$endpoint" | cut -d':' -f1)
endpoint_port=$(echo "$endpoint" | cut -d':' -f2)
address_clean=$(echo "$address" | tr -d ' ')
address_ip4=$(echo "$address_clean" | cut -d',' -f1)
address_ip6=$(echo "$address_clean" | cut -d',' -f2)
allowed_ips_clean=$(echo "$allowed_ips" | tr -d ' ')
allowed_ips_ip4=$(echo "$allowed_ips_clean" | cut -d',' -f1)
allowed_ips_ip6=$(echo "$allowed_ips_clean" | cut -d',' -f2)
sleep 1
echo ""
echo "Конфигурация сгенерирована:"
logger "Конфигурация сгенерирована:"
echo ""
#echo "$cleaned_config"
logger "$cleaned_config"
#echo ""
#echo "PrivateKey = $private_key"
#echo "S1 = $s1"
#echo "S2 = $s2"
#echo "Jc = $jc"
#echo "Jmin = $jmin"
#echo "Jmax = $jmax"
#echo "H1 = $h1"
#echo "H2 = $h2"
#echo "H3 = $h3"
#echo "H4 = $h4"
#echo "Address = $address"
#echo "address IPv4: $address_ip4"
#echo "address IPv6: $address_ip6"
#echo "PublicKey = $public_key"
#echo "AllowedIPs = $allowed_ips"
#echo "allowed_ips IPv4: $allowed_ips_ip4"
#echo "allowed_ips IPv6: $allowed_ips_ip6"
#echo "Endpoint = $endpoint"
#echo "Endpoint Host = $endpoint_host"
#echo "Endpoint Port = $endpoint_port"
#echo ""
configure_wireguard
