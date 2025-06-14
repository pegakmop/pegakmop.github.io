// ==UserScript==
// @name         Показать IP на всех сайтах
// @namespace    http://tampermonkey.net/
// @version      1.1
// @description  Показывает внешний IP на всех сайтах
// @match        *://*/*
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
                const ipDiv = document.createElement('div');
                ipDiv.style.position = 'fixed';
                ipDiv.style.top = '10px';
                ipDiv.style.right = '10px';
                ipDiv.style.padding = '8px 12px';
                ipDiv.style.backgroundColor = 'rgba(0,0,0,0.75)';
                ipDiv.style.color = '#0f0';
                ipDiv.style.zIndex = '999999';
                ipDiv.style.fontSize = '13px';
                ipDiv.style.borderRadius = '4px';
                ipDiv.style.fontFamily = 'monospace';
                ipDiv.textContent = "IP: " + data.ip;
                document.body.appendChild(ipDiv);
            } catch (e) {
                console.error("Ошибка разбора IP:", e.message);
            }
        },
        onerror: function(err) {
            console.error("Ошибка получения IP:", err);
        }
    });
})();
