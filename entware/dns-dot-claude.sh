#!/bin/sh
echo "Добавление доменов claude через днс направляя"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain claude.ai"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain claude.app"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain anthropic.com"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain statsig.com"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain statsigapi.net"
echo "Сохранение конфигурации установленных днс, чтобы после перезагрузки роутера не сбросились"
ndmc -c "system configuration save"
