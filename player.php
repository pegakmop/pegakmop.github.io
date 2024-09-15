<?php
// Устанавливаем заголовки для страницы
header('Content-Type: text/html; charset=UTF-8');

// Получаем параметр 'id' из URL
$id = isset($_GET['id']) ? htmlspecialchars($_GET['id']) : null;

// По умолчанию iframeUrl пуст
$iframeUrl = null;

if ($id) {
    // Определяем URL для API в зависимости от формата ID
    if (strpos($id, 'tt') === 0) {
        $apiUrl = 'https://kinobox.tv/api/players/?imdb=' . $id . '&sources=Collaps,Alloha,Hdvb,Videocdn,Voidboost,Kodik';
    } else {
        $apiUrl = 'https://kinobox.tv/api/players/?kinopoisk=' . $id . '&sources=Collaps,Alloha,Hdvb,Videocdn,Voidboost,Kodik';
    }

    // Выполняем запрос к API и получаем данные
    $response = @file_get_contents($apiUrl);

    if ($response !== FALSE) {
        $data = json_decode($response, true);

        // Ищем первый доступный iframeUrl в ответе
        foreach ($data as $item) {
            if (isset($item['iframeUrl'])) {
                $iframeUrl = $item['iframeUrl'];
                break;
            }
        }
    }
}

// Выводим HTML страницы
echo '<!DOCTYPE html>';
echo '<html lang="ru">';
echo '<head>';
echo '<meta charset="UTF-8">';
echo '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">';
echo '<title>Фильм/Сериал</title>';
echo '<style type="text/css">';
echo 'html, body { height: 100%; margin: 0; padding: 0; }';
echo 'iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: none; }';
echo 'p { text-align: center; font-size: 20px; color: red; }';
echo '</style>';
echo '</head>';
echo '<body>';

if ($iframeUrl) {
    // Если URL найден, выводим iframe
    echo '<iframe src="' . htmlspecialchars($iframeUrl) . '" frameborder="0" allowfullscreen webkitallowfullscreen mozallowfullscreen oallowfullscreen msallowfullscreen seamless></iframe>';
} else {
    // Если URL не найден, выводим сообщение об ошибке
    echo '<p>Ошибка: фильм или сериал не найден.</p>';
}

echo '</body>';
echo '</html>';
?>
