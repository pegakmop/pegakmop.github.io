I="$(ndmc -c 'components list' | sed -n '/^ *name:[[:space:]]*proxy$/,/^ *component:/{/^ *installed:/p}' | awk '{print $2}' | tr -d '[:space:]')" ; \
[ -n "$I" ] \
  && echo "✅ КЛИЕНТ ПРОКСИ установлен (версия $I)" \
  || { echo "❌ КЛИЕНТ ПРОКСИ не установлен — запускаю установку"; \
       ndmc -c components; \
       ndmc -c 'components install proxy'; \
       ndmc -c 'components commit'; \
       ndmc -c 'system configuration save'; }
