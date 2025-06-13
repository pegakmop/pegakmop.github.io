// ==UserScript==
// @name         @pegakmop Yandex Access Token Grabber
// @match        https://music.yandex.ru/*
// @version      1.0.1
// @description  Автоматическое получение токена с возможностью скопировать вручную, рекомендую использовать браузер teak из апстора: https://apps.apple.com/ru/app/теаk-браузер-tampermonkey/id6443938027 в настройках на открытие в связанных приложениях поставить запретить, если данный способ помог тебе, поблагодари автора, хоть словом, хоть финансово https://yoomoney.ru/to/410012481566554
// @author       @pegakmop
// @icon	     https://github.com/pegakmop/pegakmop.github.io/raw/main/PiperPied.png
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

            alert("🎟️ Yandex Access Token:\n" + token + "\n\nМожно будет скопироварь токен вручную, в следующем уведомлении, а после него можно поблагодарить автора");

            // Копируем в буфер обмена вручную
            prompt("🎟️ Скопируй токен вручную:", token);
            
            alert("🎟️ Спасибо за метод говорим @pegakmop, ну или если есть желание поддержать автора задонать на новые свершения не жалея");
            window.location.href = "https://yoomoney.ru/to/410012481566554"; 
        }
    }
})();
