// ==UserScript==
// @name         DevTools расширение
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Автоматический запуск инструментов DevTools на любой странице, возможны ошибки, тестовое решение.
// @author       @pegakmop
// @match        *://*/*
// @grant        none
// @updateURL    https://github.com/pegakmop/pegakmop.github.io/raw/main/DevTools.user.js
// @downloadURL  https://github.com/pegakmop/pegakmop.github.io/raw/main/DevTools.user.js
// @version      1.0

// ==/UserScript==

(function() {
    'use strict';

    // Функция для загрузки и инициализации Eruda
    function loadEruda() {
        let script = document.createElement('script');
        script.src = 'https://cdn.jsdelivr.net/npm/eruda';
        document.body.appendChild(script);
        script.onload = function() {
            eruda.init();
            eruda.hide();
        };
    }

    // Проверяем готовность документа
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', loadEruda);
    } else {
        loadEruda();
    }
})();
