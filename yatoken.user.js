// ==UserScript==
// @name         @pegakmop Yandex Access Token Grabber
// @match        https://music.yandex.ru/*
// @version      1.0.1
// @description  Автоматическое получение токена с возможностью скопировать вручную, рекомендую использовать браузер teak с запретом на открытие в связанных приложениях
// @author       @pegakmop
// @icon	    https://github.com/pegakmop/pegakmop.github.io/raw/main/PiperPied.png
// @run-at       document-start
// @updateURL    https://github.com/pegakmop/pegakmop.github.io/raw/main/yatoken.user.js
// @downloadURL  https://github.com/pegakmop/pegakmop.github.io/raw/main/yatoken.user.js
// ==/UserScript==

(function() {
    'use strict';

    const hash = location.hash;

    if (hash.includes("access_token=")) {
        const token = new URLSearchParams(hash.substring(1)).get("access_token");

        if (token) {
            console.log("🎟️ Yandex Access Token:", token);

            alert("🎟️ Yandex Token:\n" + token + "\n\nМожно будет скопироварь вручную, в следующем уведомлении");

            // Копируем в буфер обмена вручную
            prompt("🎟️ Скопируй токен вручную:", token);
            
            alert("🎟️ Yandex Token:\n" + token + "\n\nСпасибо за метод говорим @pegakmop");
        }
    }
})();
