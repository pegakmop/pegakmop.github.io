#!/bin/sh
# Добавление доменов
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain chatgpt.com"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain openai.com"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain oaistatic.com"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain files.oaiusercontent.com"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain gpt3-openai.com"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain openai.fund"
ndmc -c "dns-proxy tls upstream 9.9.9.9 sni dns.quad9.net domain openai.org"
# Сохранение конфигурации
ndmc -c "system configuration save"
