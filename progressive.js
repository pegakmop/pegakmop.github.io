        document.addEventListener('DOMContentLoaded', () => {
            const isStandalone = window.matchMedia('(display-mode: standalone)').matches;
            const isIOS = /iPhone|iPad|iPod/.test(navigator.userAgent) && !navigator.standalone;
            const isAndroid = /Android/.test(navigator.userAgent);

            // Показ баннера для iOS
            if (isIOS && !isStandalone) {
                const banner = `<div style="position:fixed;bottom:0;width:calc(100% - 1vw);background-color:#f8f8f8;border-top:1px solid #ddd;padding:10px;text-align:center;margin:0 1px 1px 1px;">
                    <span>Установи приложение на iPhone/iPad: </br>Нажми <img src="/ios-share.svg" style="height:20px;vertical-align:middle;" alt="Поделиться">, а затем <img src="/ios-add.svg" style="height:20px;vertical-align:middle;" alt="Добавить"> На экран "Домой"</br></span>
                    <button style="float:center;" onclick="this.parentElement.style.display='none'">Закрыть уведомление</button>
                </div>`;
                document.body.insertAdjacentHTML('beforeend', banner);
            }

            // Показ баннера для Android
            if (isAndroid && !isStandalone) {
                let deferredPrompt;
                window.addEventListener('beforeinstallprompt', (e) => {
                    e.preventDefault();
                    deferredPrompt = e;
                    const banner = `<div style="position:fixed;bottom:0;width:calc(100% - 2px);background-color:#f8f8f8;border-top:1px solid #ddd;padding:10px;text-align:center;">
                        <span>Добавить приложение на домашний экран для быстрого доступа</span>
                        <button onclick="deferredPrompt.prompt();deferredPrompt.userChoice.then(choiceResult => { if (choiceResult.outcome === 'accepted') console.log('User accepted the A2HS prompt'); deferredPrompt = null; });">Установить</button>
                        <button style="float:right;" onclick="this.parentElement.style.display='none'">Закрыть уведомление</button>
                    </div>`;
                    document.body.insertAdjacentHTML('beforeend', banner);
                });
            }

            // Показ баннера для ПК
            if (!isStandalone && !isIOS && !isAndroid) {
                let deferredPrompt;
                window.addEventListener('beforeinstallprompt', (e) => {
                    e.preventDefault();
                    deferredPrompt = e;
                    const banner = `<div style="position:fixed;bottom:0;width:calc(100% - 2px);background-color:#f8f8f8;border-top:1px solid #ddd;padding:10px;text-align:center;">
                        <span>Добавить приложение на домашний экран для быстрого доступа</span>
                        <button onclick="deferredPrompt.prompt();deferredPrompt.userChoice.then(choiceResult => { if (choiceResult.outcome === 'accepted') console.log('User accepted the A2HS prompt'); deferredPrompt = null; });">Установить</button>
                        <button style="float:right;" onclick="this.parentElement.style.display='none'">Закрыть</button>
                    </div>`;
                    document.body.insertAdjacentHTML('beforeend', banner);
                });
            }
        });

        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('./index.js').then(reg => console.log('ServiceWorker registered:', reg.scope)).catch(err => console.log('ServiceWorker registration failed:', err));
            });
        }
