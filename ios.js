          const isIos = () => {
           const userAgent = window.navigator.userAgent.toLowerCase();
           return /iphone|ipad|ipod/.test( userAgent );
       };
       // Проверяем, открыто ли приложение отдельно или в браузере
       const isInStandaloneMode = () => ('standalone' in window.navigator) && (window.navigator.standalone);



       // Если приложение открыто на iOS и в браузере, то предлагаем установить
       if (isIos() && !isInStandaloneMode()) {
           this.setState({ isShown: true }); // На примере React
       }
