ndmc -c "components list" | awk '
  $0 ~ /name: proxy/ {found=1}
  found && $1 == "queued:" {
    if ($2 == "yes") {
      print "yes"
      exit
    } else {
      print "no"
      exit
    }
  }
  found && $1 == "component:" { exit }
' | grep -q "yes" && {
  echo "✅ Компонент клиент прокси установлен"
  echo "⏳ Устанавливаю Proxy0..."
  ndmc -c "no interface Proxy0"
  ndmc -c "interface Proxy0"
  ndmc -c "interface Proxy0 description pegakmop-Proxy0-$(ip -4 -o addr show br0 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1):1080"
  ndmc -c "interface Proxy0 proxy protocol socks5"
  ndmc -c "interface Proxy0 proxy socks5-udp"
  ndmc -c "interface Proxy0 proxy upstream $(ip -4 -o addr show br0 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1) 1080"
  ndmc -c "interface Proxy0 up"
  ndmc -c "interface Proxy0 ip global 1"
  ndmc -c "system configuration save"
  echo "✅ Proxy0 успешно создан и сохранён!"
  exit 1
} || {
  echo "❌ Компонент КЛИЕНТ ПРОКСИ не установлен!"
  echo "➡️ В веб-интерфейсе: http://$(ip -4 -o addr show br0 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)"
  echo "В боковом меню ищем → Параметры системы → Изменить набор компонентов → Клиент прокси → включите галочку и сохраните."
  echo "❗️Роутер перезагрузится после сохранения, для установки компонента клиент прокси."
  echo "⚠️ Потом запустите данный скрипт заново"
  exit 1
}
