// ==UserScript==
// @name         Получение IP через GM_xmlhttpRequest
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Получает внешний IP даже при CORS ограничениях
// @match        https://passport.yandex.ru/*
// @grant        GM_xmlhttpRequest
// @connect      api.ipify.org
// ==/UserScript==

(function() {
    'use strict';

    GM_xmlhttpRequest({
        method: "GET",
        url: "https://api.ipify.org?format=json",
        onload: function(response) {
            try {
                const data = JSON.parse(response.responseText);
                alert("Ваш внешний IP: " + data.ip);
            } catch (e) {
                alert("Ошибка при разборе ответа: " + e.message);
            }
        },
        onerror: function(err) {
            alert("Не удалось получить IP: " + err.error);
        }
    });
})();
