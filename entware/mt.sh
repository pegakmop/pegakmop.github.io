#!/bin/sh
echo "Выберите действие:"
echo "1 - Установить MagiTrickle"
echo "0 - Удалить MagiTrickle"
read -r choice

if [ "$choice" = "1" ]; then
    echo "Запускаем установку..."
        # --- Начало установки ---
	    echo "@ponywka слишком много заморочек у тебя с установкой, простой скрипт который установит твой пакет последней версии с гитхаба под нужную архитектуру, вот за 10 минут написал инсталлер от @pegakmop"
	        echo "Определяем архитектуру (через opkg)..."
		    ARCH=$(opkg print-architecture | awk '
		          /^arch/ && $2 !~ /_kn$/ && $2 ~ /-[0-9]+\.[0-9]+$/ {
			          print $2; exit
				        }'
					    )

					        if [ -z "$ARCH" ]; then
						      echo "Ошибка: Не удалось определить архитектуру."
						            exit 1
							        fi

								    LATEST_VERSION=$(curl -sL "https://github.com/MagiTrickle/MagiTrickle/tags" | grep -oP 'releases/tag/\K[^"]+' | head -n 1 | tr -d '\r')

								        if [ -z "$LATEST_VERSION" ]; then
									        echo "Ошибка: Не удалось получить последнюю версию MagiTrickle."
										        exit 1
											    fi

											        PACKAGE_VERSION="${LATEST_VERSION}-1"
												    IPK_URL="https://github.com/MagiTrickle/MagiTrickle/releases/download/$LATEST_VERSION/magitrickle_${PACKAGE_VERSION}_${ARCH}.ipk"

												        echo "Скачиваем: $IPK_URL"
													    wget -O /tmp/magitrickle.ipk "$IPK_URL" || { echo "Ошибка скачивания"; exit 1; }
													        opkg install /tmp/magitrickle.ipk || { echo "Ошибка установки"; exit 1; }

														    CONFIG_DIR="/opt/var/lib/magitrickle"
														        CONFIG_FILE="$CONFIG_DIR/config.yaml"
															    CONFIG_EXAMPLE="$CONFIG_DIR/config.yaml.example"
															        CONFIG_URL="https://raw.githubusercontent.com/MagiTrickle/MagiTrickle/main/opt/var/lib/magitrickle/config.yaml.example"

																    mkdir -p "$CONFIG_DIR"

																        if [ ! -f "$CONFIG_EXAMPLE" ]; then
																	        echo "Скачиваем конфигурационный файл..."
																		        wget -O "$CONFIG_EXAMPLE" "$CONFIG_URL" || { echo "Ошибка скачивания конфига"; exit 1; }
																			    fi

																			        [ ! -f "$CONFIG_FILE" ] && cp "$CONFIG_EXAMPLE" "$CONFIG_FILE"

																				    echo "Копируем конфиг:  $CONFIG_EXAMPLE в $CONFIG_FILE"

																				        if [ ! -f "/opt/etc/init.d/S99magitrickle" ]; then
																					        echo "Ошибка: Файл S99magitrickle не найден, запуск невозможен."
																						        exit 1
																							    fi

																							        chmod +x /opt/etc/init.d/S99magitrickle
																								    /opt/etc/init.d/S99magitrickle restart || echo "Ошибка запуска сервиса"
																								        /opt/etc/init.d/S99magitrickle status || echo "Сервис уже запущен"
																									    echo "Если вам нужна отладка, то останавливаем сервис и запускаем 'демона' руками командой: /opt/etc/init.d/S99magitrickle stop
																									        magitrickled"
																										    rm -rf /tmp/magitrickle.ipk
																										        echo "Добавляем адреса в вебпанели сервиса по адресу http://<IP_Роутера>:8080"
																											elif [ "$choice" = "0" ]; then
																											    echo "Запускаем удаление..."
																											        # --- Начало удаления ---
																												    chmod +x "$0"
																												        svc_name="magitrickle"
																													    if [ -f "/opt/etc/init.d/S99$svc_name" ]; then
																													            /opt/etc/init.d/S99$svc_name stop
																														            rm -f "/opt/etc/init.d/S99$svc_name"
																															        fi

																																    rm -rf /opt/etc/magitrickle
																																        rm -rf /opt/bin/magitrickle
																																	    rm -rf /opt/sbin/magitrickle
																																	        rm -rf /opt/share/magitrickle
																																		    rm -rf /opt/var/log/magitrickle*
																																		        rm -rf /opt/var/lib/magitrickle
																																			    rm -rf /opt/etc/magitrickle.conf
																																			        rm -rf /opt/etc/magitrickle.d

																																				    #sed -i '/magitrickle/d' /opt/etc/crontab
																																				        #crontab /opt/etc/crontab

																																					    #iptables-save | grep -v "magitrickle" | iptables-restore

																																					        opkg remove magitrickle
																																						    rm -rf /tmp/magitrickle*

																																						        echo "MagiTrickle полностью удалён."
																																							else
																																							    echo "Неверный ввод. Завершаем работу."
																																							        exit 1
																																								fi
