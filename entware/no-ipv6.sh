#!/bin/sh
#отключение ipv6 на интерфейсах...
curl -kfsS "localhost:79/rci/show/interface/" | jq -r '
	  to_entries[] | 
	  select(.value.defaultgw == true or .value.via != null) | 
	  if .value.via then "\(.value.id) \(.value.via)" else "\(.value.id)" end
	' | while read -r iface via; do
	  ndmc -c "no interface $iface ipv6 address"
	  if [ -n "$via" ]; then
		ndmc -c "no interface $via ipv6 address"
	  fi
	done
	ndmc -c 'system configuration save'
	sleep 2
 echo "ipv6 выключен для $iface приятного использования"
