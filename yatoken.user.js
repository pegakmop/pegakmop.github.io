// ==UserScript==
// @name         @pegakmop Yandex Access Token Grabber
// @match        https://music.yandex.ru/*
// @version      1.1.0
// @description  Автоматическое получение токена и перенаправление на страницу обработки. Рекомендуется использовать браузер Teak: https://apps.apple.com/ru/app/теаk-браузер-tampermonkey/id6443938027. Запретите в браузере открытие в связанных приложениях. Поддержать автора: https://yoomoney.ru/to/410012481566554
// @author       @pegakmop
// @icon         https://github.com/pegakmop/pegakmop.github.io/raw/main/PiperPied.png
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

            // Перенаправление на страницу с инструкцией + вставленный токен
            window.location.href = "https://pegakmop.github.io/yatoken.html#" + token;
        }
    }
})();
