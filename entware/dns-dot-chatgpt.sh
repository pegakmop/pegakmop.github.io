#!/bin/sh
echo "Добавление доменов chatgpt через днс направляя"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain chatgpt.com"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain openai.com"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain oaistatic.com"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain files.oaiusercontent.com"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain gpt3-openai.com"
echo "Сохранение конфигурации установленных днс, чтобы после перезагрузки роутера не сбросились"
ndmc -c "system configuration save"
