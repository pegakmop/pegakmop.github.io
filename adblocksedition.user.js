// ==UserScript==
// @name         AdBlock S edition Stay userscript Script
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Remove specific elements (object, embed, applet, iframe) from the page and replace them with empty divs.
// @author       @pegakmop
// @match        *://*/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    function R(w) {
        try {
            var d = w.document,
                j, i, t, T, N, b, r = 1,
                C;
            for (j = 0; t = ["object", "embed", "applet", "iframe"][j]; ++j) {
                T = d.getElementsByTagName(t);
                for (i = T.length - 1; (i + 1) && (N = T[i]); --i) {
                    if (j !== 3 || !R((C = N.contentWindow) ? C : N.contentDocument.defaultView)) {
                        b = d.createElement("div");
                        b.style.width = N.width;
                        b.style.height = N.height;
                        b.innerHTML = "<del></del>";
                        N.parentNode.replaceChild(b, N);
                    }
                }
            }
        } catch (E) {
            r = 0;
        }
        return r;
    }

    R(window);
    var i, x;
    for (i = 0; x = window.frames[i]; ++i) R(x);
})();
