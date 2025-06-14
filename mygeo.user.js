// ==UserScript==
// @name         Geo-IP определение с фолбэками (Россия или нет)
// @namespace    http://tampermonkey.net/
// @version      1.0.0.0
// @description  Определяет IP и страну через цепочку API, даже с CORS-защитой, и показывает alert
// @match        https://*.yandex.ru/*
// @match        *://*/*
// @grant        GM_xmlhttpRequest
// @connect      api.ipify.org
// @connect      api.ipdata.co
// @connect      ipinfo.io
// @connect      api.ipgeolocation.io
// @connect      ipapi.co
// ==/UserScript==

(function() {
    'use strict';

    // Обёртка для GM_xmlhttpRequest с Promise
    function httpRequest(url) {
        return new Promise((resolve, reject) => {
            GM_xmlhttpRequest({
                method: "GET",
                url: url,
                onload: function(response) {
                    try {
                        const data = JSON.parse(response.responseText);
                        resolve(data);
                    } catch (e) {
                        reject(e);
                    }
                },
                onerror: function(err) {
                    reject(err);
                }
            });
        });
    }

    // Получаем IP
    async function getIP() {
        try {
            const res = await httpRequest("https://api.ipify.org?format=json");
            return res.ip || null;
        } catch {
            return null;
        }
    }

    // Получаем страну по IP из разных API
    async function getCountry(ip) {
        const apis = [
            {
                url: `https://api.ipdata.co/${ip}?api-key=c6d4d04d5f11f2cd0839ee03c47c58621d74e361c945b5c1b4f668f3`,
                parse: (json) => json.country_code?.toUpperCase()
            },
            {
                url: `https://ipinfo.io/${ip}/json?token=41c48b54f6d78f`,
                parse: (json) => json.country?.toUpperCase()
            },
            {
                url: `https://api.ipgeolocation.io/ipgeo?apiKey=105fc2c7e8864ec08b98e1ad4e8cbc6d&ip=${ip}`,
                parse: (json) => json.country_code2?.toUpperCase()
            },
            {
                url: `https://ipapi.co/${ip}/json`,
                parse: (json) => json.country?.toUpperCase()
            }
        ];

        for (const api of apis) {
            try {
                const res = await httpRequest(api.url);
                const country = api.parse(res);

                if (country) return country;
            } catch {
                continue;
            }
        }

        return null;
    }

    // Главная логика
    (async () => {
        const ip = await getIP();
        if (!ip) {
            alert("❌ Не удалось определить IP");
            return;
        }

        const country = await getCountry(ip);

        if (country === 'RU') {
            alert(`🛰 Ваш IP: ${ip}\n🌍 Страна: Россия\n🔌 Вы в РФ — выключите VPN, если включён.`);
        } else if (country) {
            alert(`🛰 Ваш IP: ${ip}\n🌍 Страна: ${country}\n🇷🇺 Вы не в РФ — включите VPN с локацией Россия.`);
        } else {
            alert(`🛰 Ваш IP: ${ip}\n⚠️ Страна не определена.`);
        }
    })();

})();
