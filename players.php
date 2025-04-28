<?php
header('Content-Type: text/html; charset=UTF-8');

$id = isset($_GET['id']) ? htmlspecialchars($_GET['id']) : null;
$iframeUrls = [];

if ($id) {
    if (strpos($id, 'tt') === 0) {
        $apiUrl = 'https://kinobox.tv/api/players/?imdb=' . $id . '&sources=Collaps,Alloha,Hdvb,Videocdn,Voidboost,Kodik';
    } else {
        $apiUrl = 'https://kinobox.tv/api/players/?kinopoisk=' . $id . '&sources=Collaps,Alloha,Hdvb,Videocdn,Voidboost,Kodik';
    }

    $response = @file_get_contents($apiUrl);

    if ($response !== FALSE) {
        $data = json_decode($response, true);

        foreach ($data as $item) {
            if (isset($item['iframeUrl'])) {
                $iframeUrls[] = $item['iframeUrl'];
            }
        }
    }
}

echo '<!DOCTYPE html>';
echo '<html lang="ru">';
echo '<head>';
echo '<meta charset="UTF-8">';
echo '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">';
echo '<title>Фильм/Сериал</title>';
echo '<style type="text/css">';
echo 'html, body { height: 100%; margin: 0; padding: 0; overflow: hidden; }';
echo 'iframe { position: absolute; top: 40px; left: 0; width: 100%; height: calc(100% - 40px); border: none; }';
echo 'button { position: absolute; top: 0; left: 0; width: 100%; height: 40px; font-size: 18px; cursor: pointer; background: #007BFF; color: white; border: none; }';
echo 'p { text-align: center; font-size: 20px; color: red; }';
echo '</style>';
echo '</head>';
echo '<body>';

if (!empty($iframeUrls)) {
    echo '<button onclick="nextPlayer()">сменить на другой доступный плеер</button>';
    echo '<iframe id="playerFrame" src="' . htmlspecialchars($iframeUrls[0]) . '" allowfullscreen webkitallowfullscreen mozallowfullscreen oallowfullscreen msallowfullscreen seamless></iframe>';

    echo '<script>';
    echo 'var iframeUrls = ' . json_encode($iframeUrls) . ';';
    echo 'var current = 0;';
    echo 'var playerFrame = document.getElementById("playerFrame");';

    echo 'function nextPlayer() {';
    echo '    current = (current + 1) % iframeUrls.length;';
    echo '    playerFrame.src = iframeUrls[current];';
    echo '}';

    // Автоматическая смена плеера при ошибке загрузки
    echo 'playerFrame.onerror = function() {';
    echo '    console.log("Ошибка загрузки плеера. Переключаемся на следующий.");';
    echo '    nextPlayer();';
    echo '};';

    echo '</script>';
} else {
    echo '<p>Ошибка: фильм или сериал не найден.</p>';
}

echo '</body>';
echo '</html>';
?>
