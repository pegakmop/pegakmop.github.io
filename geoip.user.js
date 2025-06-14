// ==UserScript==
// @name         Geo-IP с флагом и русскими названиями стран
// @namespace    http://tampermonkey.net/
// @version      1.4
// @description  Показывает IP, страну (на русском), флаг, город, регион, провайдер и координаты
// @match        *://*/*
// @grant        GM_xmlhttpRequest
// @connect      api.ipify.org
// @connect      api.ipdata.co
// ==/UserScript==

(function () {
    'use strict';

    const getFlagEmoji = (countryCode) => {
        if (!countryCode || countryCode.length !== 2) return '🏳️';
        return String.fromCodePoint(...[...countryCode.toUpperCase()].map(c => 0x1F1E6 + c.charCodeAt(0) - 65));
    };

    const countryNamesRU = new Map([
        ["AF", "Афганистан"], ["AL", "Албания"], ["DZ", "Алжир"], ["AD", "Андорра"], ["AO", "Ангола"],
        ["AR", "Аргентина"], ["AM", "Армения"], ["AU", "Австралия"], ["AT", "Австрия"], ["AZ", "Азербайджан"],
        ["BD", "Бангладеш"], ["BY", "Беларусь"], ["BE", "Бельгия"], ["BA", "Босния и Герцеговина"], ["BR", "Бразилия"],
        ["BG", "Болгария"], ["CA", "Канада"], ["CL", "Чили"], ["CN", "Китай"], ["CO", "Колумбия"],
        ["HR", "Хорватия"], ["CY", "Кипр"], ["CZ", "Чехия"], ["DK", "Дания"], ["EG", "Египет"],
        ["EE", "Эстония"], ["FI", "Финляндия"], ["FR", "Франция"], ["GE", "Грузия"], ["DE", "Германия"],
        ["GR", "Греция"], ["HU", "Венгрия"], ["IS", "Исландия"], ["IN", "Индия"], ["ID", "Индонезия"],
        ["IR", "Иран"], ["IQ", "Ирак"], ["IE", "Ирландия"], ["IL", "Израиль"], ["IT", "Италия"],
        ["JP", "Япония"], ["KZ", "Казахстан"], ["KE", "Кения"], ["KR", "Южная Корея"], ["KG", "Киргизия"],
        ["LV", "Латвия"], ["LB", "Ливан"], ["LT", "Литва"], ["LU", "Люксембург"], ["MY", "Малайзия"],
        ["MX", "Мексика"], ["MD", "Молдова"], ["MC", "Монако"], ["ME", "Черногория"], ["MA", "Марокко"],
        ["NL", "Нидерланды"], ["NZ", "Новая Зеландия"], ["NG", "Нигерия"], ["MK", "Северная Македония"],
        ["NO", "Норвегия"], ["PK", "Пакистан"], ["PA", "Панама"], ["PE", "Перу"], ["PH", "Филиппины"],
        ["PL", "Польша"], ["PT", "Португалия"], ["QA", "Катар"], ["RO", "Румыния"], ["RU", "Россия"],
        ["SA", "Саудовская Аравия"], ["RS", "Сербия"], ["SG", "Сингапур"], ["SK", "Словакия"], ["SI", "Словения"],
        ["ZA", "ЮАР"], ["ES", "Испания"], ["LK", "Шри-Ланка"], ["SE", "Швеция"], ["CH", "Швейцария"],
        ["SY", "Сирия"], ["TW", "Тайвань"], ["TH", "Таиланд"], ["TJ", "Таджикистан"], ["TN", "Тунис"],
        ["TR", "Турция"], ["TM", "Туркменистан"], ["UA", "Украина"], ["AE", "ОАЭ"], ["GB", "Великобритания"],
        ["US", "США"], ["UZ", "Узбекистан"], ["VE", "Венесуэла"], ["VN", "Вьетнам"], ["YE", "Йемен"]
        // Добавь больше стран при необходимости
    ]);

    const getCountryNameRU = (code) => countryNamesRU.get(code) || code || 'Неизвестно';

    const request = (url) => new Promise((resolve, reject) => {
        GM_xmlhttpRequest({
            method: "GET",
            url: url,
            onload: (res) => {
                try {
                    resolve(JSON.parse(res.responseText));
                } catch {
                    reject("Ошибка разбора JSON");
                }
            },
            onerror: (e) => reject(e)
        });
    });

    async function run() {
        try {
            const ipResp = await request("https://api.ipify.org?format=json");
            const ip = ipResp.ip;

            const geo = await request(`https://api.ipdata.co/${ip}?api-key=c6d4d04d5f11f2cd0839ee03c47c58621d74e361c945b5c1b4f668f3`);

            const {
                city, region, country_code: cc, asn, organisation, timezone, latitude, longitude
            } = geo;

            const flag = getFlagEmoji(cc);
            const ruCountry = getCountryNameRU(cc);

            alert(
                `🛰 IP: ${ip}\n` +
                `${flag} Страна: ${ruCountry} (${cc})\n` +
                `🏙 Город: ${city || "Неизвестно"}, ${region || ""}\n` +
                `🌐 Провайдер: ${asn?.name || organisation || "Неизвестно"}\n` +
                `🕓 Время: ${timezone || "Неизвестно"}\n` +
                `📍 Координаты: ${latitude}, ${longitude}`
            );

        } catch (e) {
            alert("❌ Ошибка при получении данных: " + e);
        }
    }

    run();
})();
